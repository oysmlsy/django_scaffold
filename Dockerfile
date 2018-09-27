FROM centos:7

LABEL maintainer="oysmlsy@gmail.com"
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

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
ENV TZ=Asia/Shanghai APP_DEBUG=false APP_DEPLOY=true
EXPOSE 80
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]