# only works with the Java extension of yacc: 
# byacc/j from http://troi.lincom-asg.com/~rjamison/byacc/

JFLEX  = java -jar jflex.jar
BYACCJ =./yacc.linux -tv -J
JAVAC  = javac
TESTS_DIR = ./tests

# targets:

all: Parser.class

run: Parser.class
	java Parser

build: clean Parser.class

clean:
	rm -f *~ *.class *.o *.s Yylex.java Parser.java y.output

Parser.class: Yylex.java Parser.java
	$(JAVAC) Parser.java

Yylex.java: lexico.flex
	$(JFLEX) lexico.flex

Parser.java: exerc.y Yylex.java
	$(BYACCJ) exerc.y

run-tests: Parser.class
	@TESTS=$$(find $(TESTS_DIR) -type f); \
	TOTAL=0; \
	CORRECT=0; \
	for file in $$TESTS; do \
		echo "Running Parser on $$file..."; \
		if echo $$file | grep -q "pass"; then \
			EXPECTED=0; \
		elif echo $$file | grep -q "fail"; then \
			EXPECTED=1; \
		else \
			echo "Skipping $$file: filename must contain 'pass' or 'fail'"; \
			continue; \
		fi; \
		java Parser < $$file > /dev/null 2>&1; \
		RESULT=$$?; \
		if [ $$EXPECTED -eq 0 ] && [ $$RESULT -eq 0 ]; then \
			echo "✅ $$file: PASSED as expected."; \
			CORRECT=$$((CORRECT + 1)); \
		elif [ $$EXPECTED -ne 0 ] && [ $$RESULT -ne 0 ]; then \
			echo "✅ $$file: FAILED as expected."; \
			CORRECT=$$((CORRECT + 1)); \
		else \
			echo "❌ $$file: UNEXPECTED RESULT!"; \
		fi; \
		TOTAL=$$((TOTAL + 1)); \
		echo ""; \
	done; \
	echo "==============================="; \
	echo "Summary: $$CORRECT / $$TOTAL tests had the expected result."; \
	echo "==============================="