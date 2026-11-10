#!/usr/bin/env bash
set -e
swiftc Sources/greeter/Calculator.swift Sources/greeter/MathAST.swift Sources/greeter/ExactMath.swift Tests/CasioEvaluatorTests.swift -o /tmp/test_runner
/tmp/test_runner
