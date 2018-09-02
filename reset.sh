#!/bin/sh

find . -not -path "*/venv/*" -path "*/migrations/*.pyc" -delete &&
find . -not -path "*/venv/*" -path "*/migrations/*.py" -not -name "__init__.py" -delete &&
rm -rf *.sqlite3 media static &&

python manage.py makemigrations &&
python manage.py migrate &&
python manage.py init &&
python manage.py runserver