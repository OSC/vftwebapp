#!/bin/bash -l

if [ $# -eq 0  ]; then
  echo "Please supply a tag version"
  echo "e.g.: $0 v0.0.2"
  exit 1
fi

module load ruby

git fetch --tags
git checkout ${2}
if [ -d "wiki" ]; then
  cd wiki
  git pull
  cd ..
fi
bin/bundle install --path=vendor/bundle
bin/rake assets:clobber RAILS_ENV=production
bin/rake assets:precompile RAILS_ENV=production
bin/rake tmp:clear RAILS_ENV=production
touch ../.tmp/vftwebapp_v2/restart.txt
