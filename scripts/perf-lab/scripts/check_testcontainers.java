///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.testcontainers:testcontainers:2.0.4
//DEPS org.slf4j:slf4j-simple:2.0.17

import org.testcontainers.DockerClientFactory;

public class check_testcontainers {
    public static void main(String[] args) throws Exception {
        if (DockerClientFactory.instance().isDockerAvailable()) {
            System.out.println("Container runtime is available");
        }
        else {
            throw new RuntimeException("Container runtime not found!");
        }
    }
}
