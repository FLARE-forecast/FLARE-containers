const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const shell = require('shelljs');
const cp = require('child_process');

app.use(bodyParser.json());

app.post('/init', function (req, res) {
    try {
        res.status(200).send();
    }
    catch (e) {
        res.status(500).send();
    }
});

app.post('/run', function (req, res) {
    var payload = (req.body || {}).value;
    let ret = "";


    shell.echo(payload.ssh_key.join('\n')).to('/home/user/id_rsa');

    "FLARE_VERSION" in payload && payload.FLARE_VERSION != "latest"? shell.exec(`wget -O - https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/${payload.FLARE_VERSION}/commons/flare-install.sh | /usr/bin/env bash -s ${payload.container_name} ${payload.FLARE_VERSION}`): shell.exec(`wget -O - https://raw.githubusercontent.com/FLARE-forecast/FLARE-containers/latest/commons/flare-install.sh | /usr/bin/env bash -s ${payload.container_name} latest`);
    const process1 = cp.spawnSync('/bin/bash', ['/openwhisk/flare_pullworkdir.sh', `${payload.s3_endpoint}`, `${payload.s3_access_key}`, `${payload.s3_secret_key}`, `${payload.container_name}`, `${payload.lake}`], { stdio: 'inherit' });
    if(!process1.status){

        if(`${payload.container_name}`==`flare-generate-forecast`){
            shell.exec( `/bin/bash /home/user/flare-host/${payload.container_name}/flare-host.sh -d --openwhisk`);
            shell.echo(`Second run of flare-host.sh`);
            shell.exec( `current_date=$(date +%Y%m%d)`);
            shell.exec( `yq w -i run_configuration.yml start_day_local "$(date -d "$current_date - 4 days" +%Y-%m-%d)"`);
            shell.exec( `yq w -i run_configuration.yml forecast_start_day_local "$(date -d "$current_date - 3 days" +%Y-%m-%d)"`);
            shell.cp('run_configuration.yml', '/home/user/flare/shared/flare-generate-forecast/forecast/configuration_files/');
            shell.mkdir(`/home/user/.ssh`);
            shell.cp(`/home/user/id_rsa`, `/home/user/.ssh/`);
        }

        const process2 = cp.spawnSync('/bin/bash', [`/home/user/flare-host/${payload.container_name}/flare-host.sh`, '-d', '--openwhisk'], { stdio: 'inherit' });
        if(!process2.status){
                const process3 = cp.spawnSync('/bin/bash', ['/openwhisk/flare_pushworkdir.sh', `${payload.s3_endpoint}`, `${payload.s3_access_key}`, `${payload.s3_secret_key}`, `${payload.container_name}`, `${payload.lake}`], { stdio: 'inherit' });
                if(!process3.status){
                    var next_trigger_payload_init = JSON.stringify(payload);
                    const process4 = cp.spawnSync('/bin/bash', ['/openwhisk/flare_triggernext.sh', `${payload.openwhisk_apihost}`, `${payload.openwhisk_auth}`, `${payload.container_name}`, `${payload.lake}`, `${next_trigger_payload_init}`], { stdio: 'inherit' });
                    if(!process4.status){
                        ret += "success";
                    }
                    else{
                        ret += "error in running flare_triggernext.sh; ";
                    }
                }
                else{
                    ret += "error in running flare_pushworkdir.sh; ";
                }
        }
        else{
            ret += "error in running flare-host.sh; ";
        }
    }
    else{
        ret = "error in running flare_pullworkdir.sh; ";
    }


    shell.rm('/home/user/id_rsa');

    var result = { ret:ret };
    res.status(200).json(result);

});

app.listen(8080, function () {
    console.log('Listening on port 8080')
})
