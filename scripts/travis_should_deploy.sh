#!/bin/bash

# Travis CI environment variables documentation:
# https://docs.travis-ci.com/user/environment-variables/

# Enums
DO_DEPLOY=0
SKIP_DEPLOY=1
TRAVIS_TEST_RESULT_SUCCESS=0

# Don't deploy pull-requests
# TRAVIS_PULL_REQUEST: The pull request number if the current job is a pull request,
#                      “false” if it’s not a pull request.
if [[ $TRAVIS_PULL_REQUEST != false ]]; then
  exit $SKIP_DEPLOY
fi

# Always deploy staging
if [[ $TRAVIS_BRANCH == staging ]]; then
  exit $DO_DEPLOY
fi

# On master, deploy only if tests suceeded.
# Commented out because we don't deploy master via Travis CI currently.
#
# if [[ $TRAVIS_BRANCH == master && $TRAVIS_TEST_RESULT == $TRAVIS_TEST_RESULT_SUCCESS ]]; then
#   exit $DO_DEPLOY
# fi

exit $SKIP_DEPLOY
