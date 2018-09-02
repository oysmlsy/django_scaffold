# 搭建 Django 项目脚手架

## 为项目创建目录结构

假定项目的名称为 app。

创建项目根目录：

    $ cd <some path>
    $ mkdir django_scaffold
    $ cd django_scaffold

在 django_scaffold 目录中创建并加载 Python 虚拟环境，以隔离本地包依赖：

    $ virtualenv venv
    $ source venv/bin/activate

在虚拟环境中安装 Django：

    $ pip install Django==1.11.11

可以使用`-i`参数来指定 PyPI 国内源：

    $ pip install Django==1.11.11 -i https://mirrors.aliyun.com/pypi/simple/

创建 requirements.txt 文件，同时将项目的依赖保存至其中：

    $ pip freeze > requirements.txt

创建一个名为 lib 的 Python Package，用于存放需要针对本项目做一些修改的第三方依赖：

    $ mkdir lib
    $ touch lib/__init__.py

在当前目录中创建 Django 项目（注意命令最后的点）：

    $ django-admin startproject app .

此时项目的目录结构为：

    --- <some path>
        --- django_scaffold/
            --- app/
            --- lib/
            --- venv/
            --- manage.py
            --- requirements.txt

## 修改一些 Django 项目中常用的配置

对 \<some path\>/django_scaffold/app/settings.py 做如下修改：

    # -*- coding: utf-8 -*-
    from django.contrib import admin

    admin.site.site_header = admin.site.site_title = u'XX后台管理系统'

    ALLOWED_HOSTS = ['*']

    LANGUAGE_CODE = 'zh-Hans'
    TIME_ZONE = 'Asia/Shanghai'
    USE_I18N = True
    USE_L10N = True
    USE_TZ = True

    STATIC_URL = '/static/'
    STATIC_ROOT = os.path.join(BASE_DIR, 'static')
    MEDIA_URL = '/media/'
    MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

对 \<some path\>/django_scaffold/app/urls.py 做如下修改：

    from django.conf import settings
    from django.conf.urls.static import static

    urlpatterns = [
        ...
    ] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

## 制作用于初始化数据的自定义命令

在 \<some path\>/django_scaffold/app 目录中创建 init 应用：

    $ cd <some path>/django_scaffold/app
    $ python ../manage.py startapp init

删除 init 应用中不需要的模块：

    $ cd init
    $ rm -rf admin.py models.py tests.py views.py migrations/

将 \<some path\>/django_scaffold/app/init/apps.py 文件中的类定义由

    class InitConfig(AppConfig):
        name = 'init'

改为：

    class InitConfig(AppConfig):
        name = 'app.init'

INSTALLED_APPS 里面要包含 init 应用：

    INSTALLED_APPS = [
        ...
        'app.init.apps.InitConfig',
    ]

在 init 应用中创建自定义命令的 Python package：

    $ cd <some path>/django_scaffold/app/init
    $ mkdir -p management/commands
    $ touch management/__init__.py management/commands/__init__.py

创建自定义命令的模块文件：

    $ touch management/commands/init.py

在其中编写基础结构代码：

    # -*- coding: utf-8 -*-
    from __future__ import unicode_literals

    from django.core.management.base import BaseCommand, CommandError
    from django.contrib.auth.models import User


    class Command(BaseCommand):
        help = 'init'

        def handle(self, *args, **options):
            User.objects.create_superuser('admin', 'admin@example.com', 'password')
            # self.stdout.write('info')
            # self.stdout.write(self.style.SUCCESS('success'))
            # self.stderr.write('danger')
            # raise CommandError('error')

以后将在上述 handle 方法中编写初始化数据的代码，正如上述代码中创建了一个超级用户。

回到项目根目录，即可运行 init 命令：

    $ cd <some path>/django_scaffold
    $ python manage.py makemigrations
    $ python manage.py migrate
    $ python manage.py init

此时项目的目录结构为：

    --- <some path>
        --- django_scaffold/
            --- app/
                --- init/
                    --- management/
                        --- commands/
                            --- __init__.py
                            --- init.py
                        --- __init__.py
                    --- __init__.py
                    --- apps.py
                --- __init__.py
                --- settings.py
                --- urls.py
                --- wsgi.py
            --- lib/
                --- __init__.py
            --- venv/
            --- db.sqlite3
            --- manage.py
            --- requirements.txt

## 制作开发用的快速重置脚本

进入项目根目录，创建脚本文件：

    $ cd <some path>/django_scaffold
    $ touch reset.sh

reset.sh 脚本中写入：

    #!/bin/sh

    find . -not -path "*/venv/*" -path "*/migrations/*.pyc" -delete &&
    find . -not -path "*/venv/*" -path "*/migrations/*.py" -not -name "__init__.py" -delete &&
    rm -rf *.sqlite3 media static &&

    python manage.py makemigrations &&
    python manage.py migrate &&
    python manage.py init &&
    python manage.py runserver

其中有一条命令是删除所有应用的 migrations 目录下的迁移文件。如果迁移文件需要进入版本库，那么应该去掉这条命令。

为脚本文件增加可执行权限：

    $ chmod u+x reset.sh

这样，在项目根目录中运行 reset.sh 文件，就可以快速重置数据并运行开发服务器了：

    $ ./reset.sh

此时项目的目录结构为：

    --- <some path>
        --- django_scaffold/
            --- app/
            --- lib/
            --- venv/
            --- db.sqlite3
            --- manage.py
            --- requirements.txt
            --- reset.sh

## 实现 Git 版本控制

进入项目根目录，创建 .gitignore 文件：

    $ cd <some path>/django_scaffold
    $ touch .gitignore

.gitignore 中写入：

    .DS_Store
    .idea/
    *.pyc
    0*.py
    *.sqlite3
    /static/
    /media/
    /venv/

创建 Git 仓库：

    $ git init

提交首次 commit：

    $ git add .
    $ git commit -m 'init'

此时项目的目录结构为：

    --- <some path>
        --- django_scaffold/
            --- app/
            --- lib/
            --- venv/
            --- .git/
            --- .gitignore
            --- db.sqlite3
            --- manage.py
            --- requirements.txt
            --- reset.sh

## 实现 Docker 部署

进入项目根目录，创建 Dockerfile 文件：

    $ cd <some path>/django_scaffold
    $ touch Dockerfile

Dockerfile 中写入：

    FROM centos:7

    LABEL maintainer="oysmlsy@gmail.com"

    RUN rpm --import /etc/pki/rpm-gpg/* && \
    yum install -y epel-release && \
    rpm --import /etc/pki/rpm-gpg/* && \
    yum install -y python-devel python2-pip MySQL-python httpd mod_wsgi && \
    yum clean all && rm -rf /var/cache/yum

    ARG PYPI_URL=https://mirrors.aliyun.com/pypi/simple/
    COPY ./requirements.txt /
    RUN pip install -i $PYPI_URL --no-cache-dir -U pip setuptools && \
    pip install -i $PYPI_URL --no-cache-dir -r requirements.txt && \
    rm -rf /requirements.txt

    ARG PROJECT_NAME=app
    WORKDIR /$PROJECT_NAME
    COPY . .
    RUN python manage.py collectstatic
    RUN mkdir log && touch log/error_log log/access_log
    RUN chown -R apache:apache /$PROJECT_NAME
    RUN echo -e "\
    <VirtualHost *:80>\n\
        Alias /media/ /$PROJECT_NAME/media/\n\
        Alias /static/ /$PROJECT_NAME/static/\n\
        <Directory /$PROJECT_NAME/media>\n\
            Require all granted\n\
        </Directory>\n\
        <Directory /$PROJECT_NAME/static>\n\
            Require all granted\n\
        </Directory>\n\
        WSGIScriptAlias / /$PROJECT_NAME/$PROJECT_NAME/wsgi.py\n\
        WSGIDaemonProcess $PROJECT_NAME python-path=/$PROJECT_NAME\n\
        WSGIProcessGroup $PROJECT_NAME\n\
        <Directory /$PROJECT_NAME/$PROJECT_NAME>\n\
            <Files wsgi.py>\n\
                Require all granted\n\
            </Files>\n\
        </Directory>\n\
        ErrorLog /$PROJECT_NAME/log/error_log\n\
        CustomLog /$PROJECT_NAME/log/access_log common\n\
    </VirtualHost>\
    " > /etc/httpd/conf.d/$PROJECT_NAME.conf
    ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TZ=Asia/Shanghai APP_DEBUG=false APP_DEPLOY=true
    EXPOSE 80
    CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

这里只需关注一条指令：`ARG PROJECT_NAME=app`，其值必须是 Django 项目的名字，即 \<some path\>/django_scaffold/app/ 中最后一个目录名：app。

通常，生产环境需要关闭 Debug、使用 MySQL 数据库，而开发环境需要打开 Debug、使用 SQLite 数据库。

Dockerfile 中设置了两个环境变量：APP_DEBUG 和 APP_DEPLOY，在 settings.py 中对应做2处修改：

将

    DEBUG = True

替换为：

    DEBUG = False if os.environ.get('APP_DEBUG') == 'false' else True

将

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
        }
    }

替换为：

    if os.environ.get('APP_DEPLOY') == 'true':
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.mysql',
                'HOST': os.environ.get('MYSQL_PORT_3306_TCP_ADDR'),
                'PORT': os.environ.get('MYSQL_PORT_3306_TCP_PORT'),
                'USER': 'root',
                'PASSWORD': os.environ.get('MYSQL_ENV_MYSQL_ROOT_PASSWORD'),
                'NAME': os.environ.get('MYSQL_ENV_MYSQL_DATABASE'),
                'OPTIONS': {
                    'charset': 'utf8mb4',
                    'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
                }
            }
        }
    else:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
            }
        }

进入项目根目录，创建 deploy.txt 文件：

    $ cd <some path>/django_scaffold
    $ touch deploy.txt

将部署命令写进 deploy.txt：

    # 设置环境变量
    PRODUCTION_NAME=django_scaffold
    PROJECT_NAME=app
    VOLUME_PATH=$HOME/volume

    # 运行数据库容器
    docker run --name ${PRODUCTION_NAME}_db -d -v $VOLUME_PATH/$PRODUCTION_NAME/db:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=$PRODUCTION_NAME mysql:5.7 --max-allowed-packet=256M --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

    # 构建镜像
    docker build -t $PRODUCTION_NAME .

    # 向数据库生成表结构
    docker run --rm --link ${PRODUCTION_NAME}_db:mysql $PRODUCTION_NAME /bin/sh -c "python manage.py makemigrations && python manage.py migrate"

    # 向数据库初始化数据
    docker run --rm --link ${PRODUCTION_NAME}_db:mysql -v $VOLUME_PATH/$PRODUCTION_NAME/media:/$PROJECT_NAME/media $PRODUCTION_NAME /bin/sh -c "python manage.py init"

    # 文件夹所有者改成 apache
    docker run --rm --link ${PRODUCTION_NAME}_db:mysql -v $VOLUME_PATH/$PRODUCTION_NAME/media:/$PROJECT_NAME/media -v $VOLUME_PATH/$PRODUCTION_NAME/log:/$PROJECT_NAME/log $PRODUCTION_NAME /bin/sh -c "chown -R apache:apache /$PROJECT_NAME"

    # 正式运行应用容器
    docker run --name $PRODUCTION_NAME --link ${PRODUCTION_NAME}_db:mysql -v $VOLUME_PATH/$PRODUCTION_NAME/media:/$PROJECT_NAME/media -v $VOLUME_PATH/$PRODUCTION_NAME/log:/$PROJECT_NAME/log -d -p 80:80 $PRODUCTION_NAME

进入项目根目录，创建 .dockerignore 文件：

    $ cd <some path>/django_scaffold
    $ touch .dockerignore

.dockerignore 中写入：

    .DS_Store
    .idea/
    **/*.pyc
    0*.py
    *.sqlite3
    /.gitignore
    /.dockerignore
    /deploy.txt
    /Dockerfile
    /reset.sh
    /static/
    /media/
    /venv/
    /.git/

此时项目的目录结构为：

    --- <some path>
        --- django_scaffold/
            --- app/
            --- lib/
            --- venv/
            --- .git/
            --- .dockerignore
            --- .gitignore
            --- db.sqlite3
            --- deploy.txt
            --- Dockerfile
            --- manage.py
            --- requirements.txt
            --- reset.sh

至此，进入项目根目录，依次执行 deploy.txt 中的 shell 命令，即可实现 Docker 方式部署。
