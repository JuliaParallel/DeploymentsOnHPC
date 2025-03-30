cmake_minimum_required(VERSION 3.10)

# set the project name
project(Hello)

# FindMPI.cmake is provided by CMake
find_package(MPI REQUIRED)

# add the executable
add_executable(Hello hello.c)

# Later, when creating an actual library or executable:
target_link_libraries(Hello PUBLIC MPI::MPI_C)