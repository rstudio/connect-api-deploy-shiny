# Deploying with APIs

This directory contains a Shiny application with supporting tools to deploy
that application into an RStudio Connect instance. The deployment tools use
the experimental content management APIs to create content, upload code, and
deploy that code so it can be served. A Docker image is provided to help
you use these deployment tools if their prerequisites are not available.

Use this directory as a starting point when building your own deployment
tools. Let us (<sol-eng@rstudio.com>) know about your experience!

## What's here?

* `app.R` -- A Shiny application that builds word clouds from "A Midsummer
   Night's Dream", "The Merchant of Venice", and "Romeo and Juliet".
   
   Uses the R packages `shiny`, `tm`, `wordcloud`, and `memoise`.
   
   Install these packages so you can try this example in your environment:
   
   From an R console:
   ```r
   install.packages(c("shiny","tm","wordcloud","memoise"),
       repos="https://cran.rstudio.com/")
   ```

* `manifest.json` -- JSON file describing the requirements of this Shiny
   application. Created with `rsconnect::writeManifest`.
  
   From the command-line:

   ```bash
   # This directory should be your current working directory.
   Rscript -e 'rsconnect::writeManifest()'
   ```
   
   From an R console:

   ```r
   # This directory should be your current working directory.
   rsconnect::writeManifest()
   ```

   > NOTE: Please use `rsconnect` version 0.8.15 or higher when generating a
   > manifest file.

   We recommend committing the `manifest.json` into your source control system
   and regenerating it whenever you push new versions of your code --
   especially when updating packages or otherwise changing its dependencies!

* `data` -- Directory containing one compressed text file for each work.

* `deploy` -- Directory containing deployment scripts for this content.

* `docker` -- Directory defining a Docker image that can optionally be used to
   help with content deploys.

## References

The RStudio Connect [API Reference](http://docs.rstudio.com/connect/api/)
contains documentation explaining each HTTP endpoint used by these scripts.
The RStudio Connect [User Guide](http://docs.rstudio.com/connect/user/) has
code recipes used while building these deployment tools.

## Deployment scripts

The deployment scripts in this directory let you create content in your
RStudio Connect instance and repeatedly deploy code for that content.

### Prerequisites

* `bash` (https://www.gnu.org/software/bash/)
* `curl` (https://curl.haxx.se)
* `jq` (https://stedolan.github.io/jq/)

   If you download `jq`, rename the downloaded binary as `jq` and place it
   somewhere in your `PATH`.

### Environment

The deployment scripts configure the target server and user authentication
with environment variables.

The `CONNECT_SERVER` environment variable indicates the target RStudio Connect
server. This environment variable must be the base URL of your instance and
end with a trailing slash.

```bash
export CONNECT_SERVER='http://connect.company.com/'
```

Some configurations have RStudio Connect behind a proxy and expose Connect
under a specific sub-path; use that proxied path in the environment
variable.

```bash
export CONNECT_SERVER='http://proxy.company.com/connect/'
```

The `CONNECT_API_KEY` environment variable indicates an API key owned by the
target "publisher" account in the `CONNECT_SERVER` RStudio Connect server.

```bash
export CONNECT_API_KEY='jIsDWwtuWWsRAwu0XoYpbyok2rlXfRWa'
```

If you do not already have an API key, you can create one in the RStudio
Connect dashboard. Visit your RStudio Connect account profile to create and
manage your API keys.

API keys are specific to a particular account and server. If you need to
target multiple RStudio Connect instances or user accounts, you will need to
manage multiple API keys. Password managers such as
[LastPass](https://www.lastpass.com) or [1Password](https://1password.com) can
help you track secrets like API keys. Be sure to annotate the password record
with the associated account and server!

### Creating Content

The `create-content.sh` script creates a new content item in your target
RStudio Connect server. The command-line arguments are taken as the title of
your content. Duplicate titles are permitted.

```bash
./deploy/create-content.sh "Shakespeare Word Clouds"
# => Created content: 491b772f-a58f-47e0-b358-3da7e288939c
```

The GUID that is returned (`491b772f-a58f-47e0-b358-3da7e288939c`) identifies
the created content. You will use that GUID when you go to deploy your code.

### Deploying Content

The `upload-and-deploy.sh` script bundles your code into a `.tar.gz` archive,
uploads that file to RStudio Connect, and requests that archive be "deployed".
Progress of the deployment operation is tracked and final status reported.

```bash
./deploy/upload-and-deploy.sh 491b772f-a58f-47e0-b358-3da7e288939c
# => Creating bundle archive: bundle.tar.gz
# => Created bundle: 468
# => Deployment task: meQSUN9aqjKexyqN
# => Building Shiny application...
# => Bundle requested R version 3.5.1; using /usr/lib/R/bin/R which has version 3.4.4
# => ...
# => Completed packrat build against R version: '3.4.4'
# => Launching Shiny application...
# => Task: meQSUN9aqjKexyqN Complete.
```

You can repeatedly deploy code to a content item. Deploy new versions of a
Shiny application as you incorporate feedback from your colleagues. Publish
new versions of an R Markdown document as you make edits and expand your
research.

> You will need to adapt this script for your content. The `bundle.tar.gz`
> archive file is created by only including the files needed by the Shiny
> application in this repository.

You cannot convert a content item from one type to another -- R Markdown
reports cannot become Shiny applications -- create a new content item to
contain the different type of content.

### Create, upload, and deploy

The `create-upload-and-deploy.sh` script performs the work of both
`create-content.sh` and `upload-and-deploy.sh` in one command. The
command-line arguments are taken as the title of your content. Duplicate
titles are permitted.

```bash
./deploy/create-upload-and-deploy.sh "Shakespeare Word Clouds"
# => Creating bundle archive: bundle.tar.gz
# => Created content: 491b772f-a58f-47e0-b358-3da7e288939c
# => Created bundle: 468
# => Deployment task: meQSUN9aqjKexyqN
# => Building Shiny application...
# => Bundle requested R version 3.5.1; using /usr/lib/R/bin/R which has version 3.4.4
# => ...
# => Completed packrat build against R version: '3.4.4'
# => Launching Shiny application...
# => Task: meQSUN9aqjKexyqN Complete.
```

Use `create-upload-and-deploy.sh` when you do not need to separate the
creation from upload/deploy phases. Use `upload-and-deploy` script for
additional deployments to your newly created item.

> You will need to adapt this script for your content. The `bundle.tar.gz`
> archive file is created by only including the files needed by the Shiny
> application in this repository.

## Using Docker for deployments

The `docker` directory defines an [Ubuntu 18.04 LTS
(Bionic)](http://releases.ubuntu.com/18.04.1/) image. This image can be
helpful whenever deploying from locations that may not have the deployment
script dependencies available, such as in continuous integration environments.

The Docker image installs following deployment script dependencies:

* `bash` (https://www.gnu.org/software/bash/)
* `curl` (https://curl.haxx.se)
* `jq` (https://stedolan.github.io/jq/)

> You do not need this Docker image if your deployment environment already has
> these tools.

You can build this image using `docker build`. Here, we give it the tag
`rstudio-connect-deployer:latest`.

```bash
docker build -t rstudio-connect-deployer:latest docker
```

You can use the Docker image combined with the deployment scripts to publish
your content. First, let's create a new content entry:

```bash
docker run --rm \
    -e CONNECT_SERVER="http://connect.company.com/" \
    -e CONNECT_API_KEY="jIsDWwtuWWsRAwu0XoYpbyok2rlXfRWa" \
    -v $(pwd):/content \
    -w /content \
    rstudio-connect-deployer:latest \
    /content/deploy/create-content.sh "Content created with Docker"
# => Created content: 3dac1a27-260c-4e56-b8c0-c6f0913d9ac5
```

The GUID that is returned (`3dac1a27-260c-4e56-b8c0-c6f0913d9ac5`) identifies
the created content. Use that GUID to deploy your code.

Now, let's deploy the Shiny application to that entry.

```bash
docker run --rm \
    -e CONNECT_SERVER="http://connect.company.com/" \
    -e CONNECT_API_KEY="jIsDWwtuWWsRAwu0XoYpbyok2rlXfRWa" \
    -v $(pwd):/content \
    -w /content \
    rstudio-connect-deployer:latest \
    /content/deploy/upload-and-deploy.sh 3dac1a27-260c-4e56-b8c0-c6f0913d9ac5
# => Creating bundle archive: bundle.tar.gz
# => Created bundle: 470
# => Deployment task: fXqbZXSlVeZIzABx
# => Building Shiny application...
# => Bundle requested R version 3.5.1; using /usr/lib/R/bin/R which has version 3.4.4
# => ...
# => Completed packrat build against R version: '3.4.4'
# => Launching Shiny application...
# => Task: fXqbZXSlVeZIzABx Complete.
```

## Workflow considerations

The deployment scripts are meant to help you to start using the RStudio
Connect content management APIs. They will probably need some adjustment to
suit your environment. Here are some considerations to keep in mind:

* Your API key is a secret and should be treated as such. Most continuous
   integration systems can handle sensitive data like passwords and keys.

   * [Travis](https://travis-ci.com) can use
      [encrypted keys](https://docs.travis-ci.com/user/encryption-keys/).
   * [Jenkins](https://jenkins.io) supports secure
      [credentials](https://jenkins.io/doc/book/using/using-credentials/).
   * [TeamCity]() allows
      [build parameters](https://confluence.jetbrains.com/display/TCD18/Typed+Parameters)
      marked as passwords.

   Do not commit your API key into the source repository with your application
   code.

* This directory layout is presented as one way of collecting R code and the
   supporting deployment tools into a single hierarchy. Your organization may
   prefer managing deployment code separate from data analysis artifacts. 
   
   For the R user: produce your R code (Shiny application, R Markdown
   document, Plumber API, etc.) together with the `manifest.json`.
   
   For the deploying engineer: use the tools in the `deploy` directory as
   example that need adapting to your environment. The `docker` directory
   provides a very basic Docker image that can help make some scripting tools
   available.

* The scripts do not prescribe when you should create new content versus
   deploying new code to existing content. That depends on the requirements of
   your organization. Some situations may call for always creating new
   content.
   
   Here is a way of creating content with the current time as a
   component of the title.
   
   ```bash
   NOW=$(date "+%Y-%m-%d %H:%M:%S")
   ./deploy/create-content.sh "Word Cloud Snapshot ${NOW}"
   ```

* Create new tools specific to your workflows. Maybe you have two servers: one
   for staging and one for production. Control updates to these environment
   with separate scripts.

   ```bash
   #!/usr/bin/env bash
   # Deploy to staging
   export CONNECT_SERVER="http://connect-staging.company.com"
   export STAGING_CONTENT="491b772f-a58f-47e0-b358-3da7e288939c"
   ./deploy/upload-and-deploy.sh "${STAGING_CONTENT}"
   ```

   ```bash
   #!/usr/bin/env bash
   # Deploy to production
   export CONNECT_SERVER="http://connect.company.com"
   export PRODUCTION_CONTENT="3dac1a27-260c-4e56-b8c0-c6f0913d9ac5"
   ./deploy/upload-and-deploy.sh "${PRODUCTION_CONTENT}"
   ```

    In this example, staging and production are different RStudio Connect
    instances and use distinct API keys. Your deploying environment needs to
    configure the `CONNECT_API_KEY` environment variable with the correct API
    key depending on the target environment.


## Origins

We are using the Word Cloud example Shiny application from
https://github.com/rstudio/shiny-examples. The R code has been updated to let
the text files containing book data reside in a `data` directory. The original
`globals.R`, `ui.R`, and `server.R` have been merged into a single `app.R`.
The `DisplayMode: Showcase` entry has been removed from the DESCRIPTION file.

A simple word cloud generator, based on [this blog post](http://pirategrunt.com/2013/12/11/24-days-of-r-day-11/) by PirateGrunt.

