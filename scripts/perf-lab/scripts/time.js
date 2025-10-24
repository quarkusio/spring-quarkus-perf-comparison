const spawn = require("child_process").spawn;
const axios = require('axios');

const pingIntervalMs = 5;
const timeoutMs = 120000;

const args = process.argv.slice(2);

if (args.length < 2) {
  console.error('Missing cmd and URL!');
  printUsage();
  process.exit(1);
}

const procCmd = args[0].replace(/\s+/g, ' ').trim();
const targetUrl = args[1].replace(/\s+/g, ' ').trim();
const cmd = procCmd.split(" ");

const startTime = new Date().getTime();

const proc = spawn(cmd[0], cmd.slice(1), { stdio: 'ignore' });

const intervalHandle = setInterval(() => {

  if ( new Date().getTime() - startTime > timeoutMs){
    console.error("Response not receieved within timeout of %d ms", timeoutMs);
    exitProcess(1);
  };

  axios.get(targetUrl)
  .then(function (response) {
	  if( response && response.status === 200 && response.data ){
	    const time = new Date().getTime() - startTime;
	    console.log(time + " ms");
	    exitProcess(0);
	  }
  })
  .catch(function (error) {
    if (error.response) {
      console.log(error.response.status);
    }
	  //    console.log(error);
  });

}, pingIntervalMs);


function exitProcess(exitCode){
  clearInterval(intervalHandle);
  proc.kill();
  process.exit(exitCode);
}

function printUsage(){
  console.log('Usage: node time.js "cmd" "url"');
  console.log('');
  console.log('"cmd": full command to start process');
  console.log('"url": URL that returns a HTTP 200 response when process is resonding to HTTP GET requests');
}