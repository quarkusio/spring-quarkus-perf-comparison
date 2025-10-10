///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.aesh:aesh:2.6
//DEPS commons-io:commons-io:2.11.0
//DEPS io.hyperfoil.tools:horreum-client:0.3
//DPES com.fasterxml.jackson.core:jackson-databind:2.13.0

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.aesh.AeshRuntimeRunner;
import org.aesh.command.Command;
import org.aesh.command.CommandDefinition;
import org.aesh.command.CommandResult;
import org.aesh.command.invocation.CommandInvocation;
import org.aesh.command.option.Option;
import org.apache.commons.io.FileUtils;
import org.aesh.command.shell.Shell;

import io.hyperfoil.tools.HorreumClient;
import io.hyperfoil.tools.horreum.entity.json.Access;

class startupUpload {

    public static void main(String... args) {
        AeshRuntimeRunner.builder().command(Uploader.class).args(args).execute();
    }

    @CommandDefinition(name = "uploader", description = "Upload runs from Jenkins to Horreum")
    public static class Uploader implements Command {

        @Option(name = "buildID", shortName = 'b', description = "Jenkins Build ID", required = true)
        private String buildID;

        @Option(name = "config", shortName = 'c', description = "Config file", required = true)
        private String config;

        static final String JENKINS_URL = "http://{jenkinsHost}/{JOB_PATH}/{BUILD_ID}/artifact/run/{ARTIFACT}";

        private static final Set<HorreumUploadConfig> tests = new HashSet<>();
        private static String jobPath;

        private static final String HORREUM_USERNAME;
        private static final String HORREUM_PASSWORD;
        private static final String JENKINS_HOST;
        private static final String HORREUM_HOST;
        private static final String KEYCLOAK_HOST;
        private static final String KEYCLOAK_REALM;
        private static final String KEYCLOAK_CLIENT_ID;

        private static HorreumClient horreumClient;

        static {
            // get creds from env
            JENKINS_HOST = System.getenv("JENKINS_HOST");
            HORREUM_HOST = System.getenv("HORREUM_HOST");
            KEYCLOAK_HOST = System.getenv("KEYCLOAK_HOST");
            KEYCLOAK_REALM = System.getenv("KEYCLOAK_REALM");
            KEYCLOAK_CLIENT_ID = System.getenv("KEYCLOAK_CLIENT_ID");

            HORREUM_USERNAME = System.getenv("HORREUM_USER");
            HORREUM_PASSWORD = System.getenv("HORREUM_PASS");

        }

        @Override
        public CommandResult execute(CommandInvocation commandInvocation) throws InterruptedException {

            if (HORREUM_USERNAME == null ||
                    HORREUM_PASSWORD == null ||
                    JENKINS_HOST == null ||
                    HORREUM_HOST == null ||
                    KEYCLOAK_HOST == null ||
                    KEYCLOAK_REALM == null ||
                    KEYCLOAK_CLIENT_ID == null) {

                        commandInvocation.getShell().writeln("ERROR: Environnement variables are not correctly set!");

                        return CommandResult.FAILURE;
            }

            try {
                horreumClient = instantiateHorreumClient();

                loadTestDefinitions(commandInvocation.getShell());

                // make tmp dir
                Path tmpDir = Files.createTempDirectory("horreum-upload-");


                // iterate through each test
                tests.forEach(entry -> processUpload(tmpDir, entry, commandInvocation.getShell()));

                return CommandResult.SUCCESS;
            } catch (Exception exception) {
                commandInvocation.getShell().writeln("ERROR: ".concat(exception.getLocalizedMessage()));
                return CommandResult.FAILURE;
            }
        }

        private void loadTestDefinitions(Shell shell) throws JsonProcessingException, IOException {
            File configFile = new File(config);

            if (!configFile.exists()) {
                throw new RuntimeException("Could not locate config file: " + configFile);
            }

            JsonNode json = new ObjectMapper().readTree(configFile);

            jobPath = json.at("/jobPath").asText();

            JsonNode artefactsNode = json.at("/artefacts");
            if (!artefactsNode.isArray()) {
                throw new RuntimeException("Config error: /artifacts should be an array");
            }

            for (final JsonNode objNode : artefactsNode) {
                shell.writeln(objNode.asText());
                tests.add(new HorreumUploadConfig(objNode.get("horreumTest").asText(), objNode.get("filePath").asText(), objNode.get("start").asText()
                    , objNode.get("stop").asText(), objNode.get("owner").asText(), objNode.get("schema").asText())
                );
            }

        }

        private String formatJenkinsUrl(String artefact) {
            String resolvedUrl = JENKINS_URL
                    .replace("{jenkinsHost}", JENKINS_HOST)
                    .replace("{JOB_PATH}", jobPath)
                    .replace("{BUILD_ID}", buildID)
                    .replace("{ARTIFACT}", artefact);

            return resolvedUrl;
        }

        private void processUpload(Path tmpDir, HorreumUploadConfig config , Shell shell) {

            String jsonUrl = formatJenkinsUrl(config.getFilePath());
            File outputFile = new File(tmpDir.toFile(), config.getFilePath());

            // download json file
            shell.writeln(String.format("Downloading %s: to %s", jsonUrl, outputFile.getAbsolutePath()));

            try {
                downloadFile(new URL(jsonUrl), outputFile);

                JsonNode json = null;
                json = new ObjectMapper().readTree(outputFile);

                // upload to horreum
                String runID = horreumClient.runService.addRunFromData(
                    config.getStart(), // start
                    config.getStop(), // stop
                    config.getName(), // test
                    config.getOwner(), // owner
                    Access.PUBLIC, // access
                    null, // token
                    config.getSchema(), // schema
                    null, // description
                    json // json
                );

                shell.writeln(String.format("Successfully uploaded data to Horreum: %s", runID));

            } catch (IOException e) {
                shell.writeln(String.format("ERROR: Failed to upload to Horreum: %s", jsonUrl));
            }

            shell.writeln(jsonUrl);
        }

        private void downloadFile(URL fileUrl, File outputFile) throws IOException {
            FileUtils.copyURLToFile(
                    fileUrl,
                    outputFile,
                    5000,
                    10_000);
        }

        private HorreumClient instantiateHorreumClient() {
            return new HorreumClient.Builder()
                    .horreumUrl(HORREUM_HOST + "/")
                    .keycloakUrl(KEYCLOAK_HOST)
                    .keycloakRealm(KEYCLOAK_REALM)
                    .clientId(KEYCLOAK_CLIENT_ID)
                    .horreumUser(HORREUM_USERNAME)
                    .horreumPassword(HORREUM_PASSWORD)
                    .build();
        }
    }
    static class HorreumUploadConfig {
        private final String name;
        private final String filepath;
        private final String start;
        private final String stop;
        private final String owner;
        private final String schema;

        public HorreumUploadConfig(String name, String filepath, String start, String stop, String owner, String schema){
            this.name = name;
            this.filepath = filepath;
            this.start = start;
            this.stop = stop;
            this.owner = owner;
            this.schema = schema;
        }

        public String getName(){
            return this.name;
        }

        public String getFilePath(){
            return this.filepath;
        }

        public String getStart(){
            return this.start;
        }

        public String getStop(){
            return this.stop;
        }

        public String getOwner(){
            return this.owner;
        }

        public String getSchema(){
            return this.schema;
        }
    }
}