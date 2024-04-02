# Introduction
We have moved a lot towards automation. Moving to Github has exposed us to [github workflows](https://docs.github.com/en/actions/using-workflows/about-workflows). Github action runner is responsible for executing a single instance of workflow at any point in time.  
- Demanding number of *(automations via)* workflows require higher availability of github action runners. *Need for scalability*;
- A shared pool of github action runners is configured for **github.softwareag/AIM**. These runners differ at various properties like *memory*, *cores*, *versions of tools*. *Need for homogeneous runners*; 

These are potential points that need solution. **Scalable Ghar** addresses need for *scalability* and *homogeneity* using containerized images customized for common requirements. 

# Scalable self hosted github action runner

A simple project to bring up an instance of self hosted github action runners dedicated to one particular repository. Teams can benefit by running dedicated action runners which can provide better turn around time and management of the runner is completely in the control of the team to resolve issues like disk space, non-availability of runners, polluted nodes.

Let's get started ! 

## Requirements
### Tools
- `docker`
- `docker-compose`
### PAT
Following permissions are required. User should have **Admin** level permission on the repository that requires runners.
- repo
- read:org
- manage_runners:org
- manage_runners:enterprise

### Environment file
Name of the environment file should be _.runner.properties.env_. This file is referred in 'docker-compose.yaml'. Keep it in the same path as the 'docker-compose.yaml'. Following properties should be set in the environment file
- owner: Either the business unit or the individual. Example _AIM_ or _innsh_
- repo: Name of the repository
- token: Personal Access Token with the above mentioned permissions granted.

Example
```properties
owner=innsh
repo=lab-repo
token=mysupersecretpat
```
## How to bring up runner?

Use the following command to bring a single instance of github action runner
```bash
docker-compose up -d 
```

## How to scale up and down?

```bash
docker-compose up -d --scale ghar=3
```
This command scales up the service name **ghar** _(in docker-compose.yaml)_ to a replica count of 3.

> At this point these containers are not yet persistant with their state. Any restart of container would reset the state. Container would, however, register itself again as a runner automatically but the history of executed jobs would be lost. _WIP_

### Logs

Use the following command to tail the logs of all the containers
```bash
docker-compose logs -f
```

## How to use these runners?
These runners are configured with the name of the repository (variable `repo` from [env file](#environment-file)) as a label. So, use the following label in your workflows
```yaml
  runs-on: [ self-hosted, <your-repo-name> ]  
```
Not having these labels would make the workflow compete for the runners in the shared pool, there by possibly delaying turn around time. Having these labels on the workflow targets these runners dedicated only to the repository.

## Where to add new tools to runner?
Add at https://github.softwareag.com/innsh/scalable-ghar/blob/main/dockerfile#L76. Once added remember to rebuild the image. Use `docker compose up --build -d ghar`. Without the `--build` switch, the older image in the local repository will be used by docker engine.
