#!/bin/bash

set -e
if ! $GITHUB_ACTION_PATH/src/check_renode_install.sh;
then
    # RENODE_DIR should be set by the action parameter
    mkdir -p $RENODE_DIR
    echo "RENODE_DIR=$RENODE_DIR" >> $GITHUB_ENV
    if ! wget --progress=dot:giga https://dl.antmicro.com/projects/renode/builds/renode-$RENODE_VERSION.linux-portable.tar.gz;
    then
        echo "There was an error when downloading the package. The provided Renode version might be wrong: $RENODE_VERSION"
        exit 1
    fi
    tar -xzf renode-$RENODE_VERSION.linux-portable.tar.gz -C $RENODE_DIR --strip 1
    if ! $GITHUB_ACTION_PATH/src/check_renode_install.sh;
    then
        echo "Tried to install Renode, but failed. Please inspect the log"
        exit 1
    fi
fi

# Install PIP requirements unconditionally.
# This is usable if Renode comes from a GH Action cache - users
# can cache RENODE_DIR to pass it between jobs, but Python dependencies
# are a bit more difficult to locate and cache.
pip install -q -r $RENODE_DIR/tests/requirements.txt --no-warn-script-location

echo "::add-matcher::$GITHUB_ACTION_PATH/src/renode-problem-matcher.json"

if [ -z "$TESTS_TO_RUN" ]
then
    echo "No tests provided, Renode is installed to $RENODE_DIR"
else
    $RENODE_DIR/test.sh $TESTS_TO_RUN
fi

echo "::remove-matcher owner=test-in-renode::"
