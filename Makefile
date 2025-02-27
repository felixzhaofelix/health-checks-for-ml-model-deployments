TEST_PATH=./tests

.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: help

build: ## build a package
	python setup.py sdist bdist_wheel
.PHONY: build

clean-build:  ## clean build artifacts
	rm -rf build
	rm -rf dist
	rm -rf vendors
	rm -rf credit_risk_model.egg-info
.PHONY: clean-build

clean-pyc: ## Remove python artifacts.
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
.PHONY: clean-pyc

venv: ## create virtual environment
	python3.9 -m venv venv
.PHONY: venv

dependencies: ## install dependencies from requirements.txt
	python -m pip install --upgrade pip
	python -m pip install --upgrade setuptools
	python -m pip install --upgrade wheel
	pip install -r requirements.txt
.PHONY: dependencies

test-dependencies: ## install dependencies from test_requirements.txt
	pip install -r test_requirements.txt
.PHONY: test-dependencies

update-dependencies:  ## Update dependency versions
	pip-compile requirements.in > requirements.txt
	pip-compile test_requirements.in > test_requirements.txt
	pip-compile service_requirements.in > service_requirements.txt
.PHONY: update-dependencies

clean-venv: ## remove all packages from virtual environment
	pip freeze | grep -v "^-e" | xargs pip uninstall -y
.PHONY: clean-venv

test: clean-pyc ## Run unit test suite.
	pytest --verbose --color=yes $(TEST_PATH)
.PHONY: clean-pyc

test-reports: clean-pyc clean-test ## Run unit test suite with reporting
	mkdir -p reports
	mkdir ./reports/unit_tests
	mkdir ./reports/coverage
	mkdir ./reports/badge
	-python -m coverage run --source credit_risk_model -m pytest --verbose --color=yes --html=./reports/unit_tests/report.html --junitxml=./reports/unit_tests/report.xml $(TEST_PATH)
	-coverage html -d ./reports/coverage
	-coverage-badge -o ./reports/badge/coverage.svg
	rm -rf .coverage
.PHONY: test-reports

clean-test:	## Remove test artifacts
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf reports
	rm -rf .pytype
.PHONY: clean-test

check-codestyle:  ## checks the style of the code against PEP8
	pycodestyle credit_risk_model --max-line-length=120
.PHONY: check-codestyle

check-docstyle:  ## checks the style of the docstrings against PEP257
	pydocstyle credit_risk_model
.PHONY: check-docstyle

check-security:  ## checks for common security vulnerabilities
	bandit -r credit_risk_model
.PHONY: check-security

check-dependencies:  ## checks for security vulnerabilities in dependencies
	safety check -r requirements.txt
.PHONY: check-dependencies

check-codemetrics:  ## calculate code metrics of the package
	radon cc credit_risk_model
.PHONY: check-codemetrics

check-pytype:  ## perform static code analysis
	pytype credit_risk_model
.PHONY: check-pytype

convert-post:  ## Convert the notebook into Markdown file
	jupyter nbconvert --to markdown blog_post/blog_post.ipynb --output-dir='./blog_post' --TagRemovePreprocessor.remove_input_tags='{"hide_code"}'
.PHONY: convert-post

build-image:  ## Build docker image
	export BUILD_DATE=`date -u +'%Y-%m-%dT%H:%M:%SZ'` && \
	docker build --build-arg BUILD_DATE \
		-t credit_risk_model_service:latest .
.PHONY: build-image
