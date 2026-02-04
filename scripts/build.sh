#!/usr/bin/env bash

set -e
set -o pipefail

WORKSPACE_DIR=$(pwd)

echo "Workspace Dir: $WORKSPACE_DIR"
echo ""

# Update and install system dependencies
echo "Installing system dependencies..."
apt update -qq
apt install -y \
    libboost-log-dev \
    python3-colcon-common-extensions \
    python3-rosdep

# Initialize rosdep if needed
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    echo "Initializing rosdep..."
    rosdep init
fi
rosdep update

# Install ROS package dependencies from package.xml
# Skip custom packages that don't exist in rosdep
echo "Installing ROS dependencies..."
rosdep install --from-paths . --ignore-src -r -y \
    --skip-keys="riptide_msgs2 chameleon_tf_msgs nortek_dvl_msgs" || true

# Build the package
echo ""
echo "Building workspace..."
colcon build \
    --cmake-force-configure \
    --base-paths . \
    --install-base INSTALL_BASE \
    --event-handlers console_direct+ \
    --packages-select riptide_autonomy2

echo ""
echo "Build completed successfully!"
echo ""

# Source the workspace
source INSTALL_BASE/setup.bash

# Run tests (allow failure to capture results)
echo "Running tests..."
set +e
colcon test \
    --return-code-on-test-failure \
    --base-paths . \
    --install-base INSTALL_BASE \
    --event-handlers console_direct+ \
    --packages-select riptide_autonomy2

TEST_STATUS=$?
set -e

# Show test results if tests failed
if [[ $TEST_STATUS != 0 ]]; then
    colcon test-result --test-result-base INSTALL_BASE --all --verbose
    exit $TEST_STATUS
fi


exit 0