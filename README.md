CRUDS
=====

[![Build Status](https://travis-ci.org/ksnabb/cruds.png?branch=develop)](https://travis-ci.org/ksnabb/cruds)

This branch 0.1.x is supposed to fix issues that was noticed in the first version of CRUDS. These issues are the following:

 * File support and express middleware problems
 * Own implementation of event emmitter had scope and concurrency problems
 * Mongoose Schema support and internal use of mongoose models might be practical.
 * Socket.io complexities and setup
 * Tests was not extensive enough and did not reflect real cases of code

 Solutions for the problems will be:

 * File support implementation together with options passing for the cruds creation
 * Use node.js EventEmitter module
 * Mongoose usage 
 * Socket.io will be changed to ws which will work out of the box
 * Moving to ws we need to rethink and redesign the subscription algorithm
 * Tests will be written in mocha and run normally + with phantomjs
 * More focus and measurements on speed and performance will be done
 * use grunt for building the project

 Please comment if there are other improvement suggestions for the CRUDS module.


