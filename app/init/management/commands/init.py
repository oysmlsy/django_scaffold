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
