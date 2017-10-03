#!/bin/bash
teams=(
  frontend
  backend 
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
