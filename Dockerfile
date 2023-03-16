FROM python:3.9-alpine3.13
LABEL maintainer="yu"
#who's gonna maintain thia image


ENV PYTHONUNBUFFERED 1
#TELLS PYTHON DO NOT WANT TO BUFFER THE OUTPUT FROM PYTHON WILL BE PRINTED TO THE CONSOLE, WHICH PREVENTS ANT DELAYS OF MESSAGES, MEANING WE CAN SEE THE LOGS IMMEDIATELY.

COPY ./requirements.txt /tmp/requirements.txt
#把檔案複製一分到container的這個位置裡面
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
#we have this file available during the build phase.


COPY ./app /app
#把檔案複製一分到container的這個位置裡面

WORKDIR /app
EXPOSE 8000


ARG DEV=false
#we're overriding this insdie the docker-compose file by sepecifing args dev equals to true
#So when we use Dockerfile through the docker-compose configuration, it's gonna update this dev variable to true. Whereas when we use it in any other Docker-compose configuration, it's gonna leave it as false,so by default we're not running in development mode.
#(所以一般情況我們都是在啥mode??)

#command that would run when we're building image
RUN python -m venv /py && \ 
#Because Each instruction creates one layer
#所以老師在這他用 &&\ 去做分隔，這樣就只會創建一個layer
#而不是用很多個RUN 去執行這邊每一行的 && \
#which can keep our image lightweight as possible.
#然後venv代表虛擬環境， 用這是因為一些image裡面的py的dependencues可能和你自己裝的會有衝突之類的
#所以總之就是prevent any conflicring dependencies
#that may come in the base image you're using.

    /py/bin/pip install --upgrade pip &&\
    #update pip(python package manager) inside our virtual env
    /py/bin/pip install -r /tmp/requirements.txt &&\
    #install the requirements inside the Docker image.
    #actually this is installed inside the virtual env
    #coz 這邊是設定 py/bin/pip(就是代表虛擬環境)

    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    #shell script, not the typo.It's the way you end the statement by writing it backwards, like 'fi'.
    #Anyway, if we build it without dev being true, the dev dependencies are ont installed on our Docker image, which saves a little bit of space and also adds a little bit of security because oyu do not need to worry about the bugs and things in the "development" dependencies if you do not install'em on your "production" image.


    rm -rf /tmp && \
    #remove the tmp directory, coz we do not want any extra dependencies on our image once it's being created. It's best practice to keep Docker images as lightweight as possible.
    #So it there's any file tiy do not need on the actual image, make sure to remove them as part of your build process.
    #(So ant file you just need temporarily, you add it, use it inside the Dockerfile and then remove it before the end of the Dockerfile.)
    #This can save a lot of space and speed when you're deploying your app.

    adduser \ 
    #add new user inside our image. Coz it's best practice not to user the root user.
    #If we did not specify this,the only user available inside the alpine image that we're using would be the root user(has the full acces and premissons to do everything on the sercer).
    #Just do not user root user, coz if your app gets compromised, the attacker may have full access to everything on that Docker container.
    #But if you do not use root user,the attacker can only do what limited user can do.
        --disabled-password \
        #uesr do not need to log in with password, just by default
        --no-create-home \
        #do not want to create home directory
        django-user
        #call the user using this container 'django user', you can call it whatever you want.

ENV PATH="/py/bin:$PATH"
#update the  environment variable inside the image and we're updating the path env variable
#And 'path' is the env variable that's automatically created on Linux OS, what is does it's define all of the directory where all the executables(?) can be run.
#And what we do here is because we run the command on the virtual environment, we do not want to specify /py/bin everytime, so we specify this variable here, that way, whenever we run any py commands it will run automatically from our vitual environment. 

USER django-user
#until run this line ,everything else is being done as the root user,but we will run using the last user the image switched to,which is django user.