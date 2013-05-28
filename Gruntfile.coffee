module.exports = (grunt) ->
  grunt.initConfig
    pkg: '<json:package.json>'

    coffee:
      options:
        sourceMap: true
      app:
        expand: true
        cwd: 'src'
        src: '**/*.coffee'
        dest: 'app/'
        ext: '.js'

    coffeelint:
      app: ['src/**/*.coffee', 'test/**/*.coffee']
      options:
        max_line_length:
          value: 100
        no_empty_param_list:
          value: true

    copy:
      app:
        expand: true
        cwd: 'src'
        src: '**/*.js'
        dest: 'app/'

    mochacov:
      options:
        timeout: 10000
        ui: 'bdd'
        reporter: 'spec'
        compilers: ['coffee:coffee-script']
      test:
        src: ['test/**/*.coffee']
      coverage:
        src: ['test/**/*.coffee']
        options:
          coveralls:
            serviceName: 'travis-ci'
            repoToken: process.env.COVERALLS_REPO_TOKEN
        

    watch:
      files: [
        'package.json'
        'Gruntfile.coffee'
        'src/**/*.coffee'
        'test/**/*.coffee'
      ]
      tasks: 'default'
      
    nodemon:
      dev:
        options:
          file: 'app/server.js'
          watchedFolders: ['app']
          delayTime: 1

    concurrent:
      target:
        tasks: ['nodemon', 'watch']
        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-mocha-cov'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-nodemon'
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  
  grunt.registerTask 'compile', ['coffee', 'coffeelint', 'copy']
  grunt.registerTask 'test', ['compile', 'mochacov:test']
  grunt.registerTask 'ci', ['compile', 'mochacov:coverage']
  grunt.registerTask 'develop', ['concurrent']
  grunt.registerTask 'default', ['test']