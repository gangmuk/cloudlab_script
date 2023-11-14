#!/bin/bash

pip install -r requirements.txt
pyinfra inventory.py deploy.py
