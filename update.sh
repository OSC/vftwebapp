#!/bin/bash

if [ $# -eq 0  ]; then
  echo "Please supply a tag version"
  echo "e.g.: $0 v0.0.2"
  echo "e.g.: $0 master"
  exit 1
fi

update ()
{
  TAG=${1} RAILS_ENV=production scl enable git19 rh-ruby22 -- /bin/bash <(
    cat <<\EOF
      git fetch --tags &&
      git checkout ${TAG} &&
      ( cd 'wiki' 2> /dev/null && git pull || true ) &&
      bin/bundle install --path=vendor/bundle &&
      bin/rake assets:clobber &&
      bin/rake assets:precompile &&
      bin/rake tmp:clear &&
      touch tmp/restart.txt
EOF
  )
}

update ${1}
