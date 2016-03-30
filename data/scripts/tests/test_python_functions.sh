#!/bin/bash
# Python module functions testing script
#
# Version: 20160330

EXIT_SUCCESS=0;
EXIT_FAILURE=1;
EXIT_IGNORE=77;

TEST_PREFIX=`dirname ${PWD}`;
TEST_PREFIX=`basename ${TEST_PREFIX} | sed 's/^lib\([^-]*\)/\1/'`;

TEST_PROFILE="py${TEST_PREFIX}";
TEST_FUNCTIONS="get_version";
TEST_FUNCTIONS_WITH_INPUT="open_close seek read";
OPTION_SETS="";

TEST_TOOL_DIRECTORY=".";
INPUT_DIRECTORY="input";
INPUT_GLOB="*";

test_callback()
{
	local TMPDIR=$1;
	local TEST_SET_DIRECTORY=$2;
	local TEST_OUTPUT=$3;
	local TEST_SCRIPT=$4;
	local TEST_INPUT=$5;
	shift 5;
	local ARGUMENTS=$@;

	local RESULT=0;

	if test `uname -s` = 'Darwin';
	then
		DYLD_LIBRARY_PATH="../lib${TEST_PREFIX}/.libs/" PYTHONPATH="../py${TEST_PREFIX}/.libs/" ${PYTHON} ${TEST_SCRIPT} ${ARGUMENTS[*]} "${INPUT_FILE}" > /dev/null 2>&1;
		RESULT=$?;
	else
		LD_LIBRARY_PATH="../lib${TEST_PREFIX}/.libs/" PYTHONPATH="../py${TEST_PREFIX}/.libs/" ${PYTHON} ${TEST_SCRIPT} ${ARGUMENTS[*]} "${INPUT_FILE}" > /dev/null 2>&1;
		RESULT=$?;
	fi
	return ${RESULT};
}

test_python_function()
{
	local TEST_PROFILE=$1;
	local TEST_FUNCTION=$2;
	local OPTION_SETS=$3;

	local TEST_SCRIPT="${TEST_TOOL_DIRECTORY}/py${TEST_PREFIX}_test_${TEST_FUNCTION}.py";

	if ! test -f ${TEST_SCRIPT};
	then
		echo "Missing test Python script: ${TEST_SCRIPT}";

		exit ${EXIT_FAILURE};
	fi
	echo -n -e "Testing Python-bindings function: py${TEST_PREFIX}.${TEST_FUNCTION}\t";

	local RESULT=0;

	# TODO: add support for TEST_PROFILE and OPTION_SETS?
	if test `uname -s` = 'Darwin';
	then
		DYLD_LIBRARY_PATH="../lib${TEST_PREFIX}/.libs/" PYTHONPATH="../py${TEST_PREFIX}/.libs/" ${PYTHON} ${TEST_SCRIPT} > /dev/null 2>&1;
		RESULT=$?;
	else
		LD_LIBRARY_PATH="../lib${TEST_PREFIX}/.libs/" PYTHONPATH="../py${TEST_PREFIX}/.libs/" ${PYTHON} ${TEST_SCRIPT} > /dev/null 2>&1;
		RESULT=$?;
	fi

	if test ${RESULT} -ne ${EXIT_SUCCESS};
	then
		echo "(FAIL)";
	else
		echo "(PASS)";
	fi
	return ${RESULT};
}

test_python_function_with_input()
{
	local TEST_PROFILE=$1;
	local TEST_FUNCTION=$2;
	local OPTION_SETS=$3;
	local INPUT_DIRECTORY=$4;
	local INPUT_GLOB=$5;

	local TEST_SCRIPT="${TEST_TOOL_DIRECTORY}/py${TEST_PREFIX}_test_${TEST_FUNCTION}.py";

	if ! test -f ${TEST_SCRIPT};
	then
		echo "Missing test Python script: ${TEST_SCRIPT}";

		exit ${EXIT_FAILURE};
	fi

	run_test_on_input_directory "${TEST_PROFILE}" "${TEST_FUNCTION}" "with_callback" "${OPTION_SETS}" "${TEST_SCRIPT}" "${INPUT_DIRECTORY}" "${INPUT_GLOB}";
	local RESULT=$?;

	return ${RESULT};
}

if ! test -z ${SKIP_PYTHON_TESTS};
then
	exit ${EXIT_IGNORE};
fi

PYTHON=`which python${PYTHON_VERSION} 2> /dev/null`;

if ! test -x ${PYTHON};
then
	echo "Missing executable: ${PYTHON}";

	exit ${EXIT_FAILURE};
fi

TEST_RUNNER="tests/test_runner.sh";

if ! test -f "${TEST_RUNNER}";
then
	TEST_RUNNER="./test_runner.sh";
fi

if ! test -f "${TEST_RUNNER}";
then
	echo "Missing test runner: ${TEST_RUNNER}";

	exit ${EXIT_FAILURE};
fi

source ${TEST_RUNNER};

for TEST_FUNCTION in ${TEST_FUNCTIONS};
do
	test_python_function "${TEST_PROFILE}" "${TEST_FUNCTION}" "${OPTION_SETS}";
	RESULT=$?;

	if test ${RESULT} -ne ${EXIT_SUCCESS};
	then
		break;
	fi
done

if test ${RESULT} -ne ${EXIT_SUCCESS};
then
	exit ${RESULT};
fi

for TEST_FUNCTION in ${TEST_FUNCTIONS_WITH_INPUT};
do
	test_python_function_with_input "${TEST_PROFILE}" "${TEST_FUNCTION}" "${OPTION_SETS}" "${INPUT_DIRECTORY}" "${INPUT_GLOB}";
	RESULT=$?;

	if test ${RESULT} -ne ${EXIT_SUCCESS};
	then
		break;
	fi
done

exit ${RESULT};
