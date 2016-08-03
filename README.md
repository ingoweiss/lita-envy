# lita-envy

[![Build Status](https://travis-ci.org/ingoweiss/lita-envy.png?branch=master)](https://travis-ci.org/ingoweiss/lita-envy)
[![Coverage Status](https://coveralls.io/repos/ingoweiss/lita-envy/badge.png)](https://coveralls.io/r/ingoweiss/lita-envy)

Record and retrieve information about environment usage 

## Installation

Add lita-envy to your Lita instance's Gemfile:

``` ruby
gem "lita-envy"
```

## Configuration

``` ruby
config.handlers.envy.namespace = 'my_project'
```

## Usage

``` bash
@bot claim ENV123
@bot release ENV123
@bot forget ENV123
@bot envs
@bot wrestle ENV123 from Jon Doe
```

