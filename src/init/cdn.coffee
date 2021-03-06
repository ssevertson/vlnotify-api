async = require 'async'
aws = require 'aws-sdk'

module.exports.name = 'cdn'

module.exports.attach = ->
  aws.config.update @config.get('aws:config')
  @storage = new aws.S3()
  @storage.buckets ?= {}
  @cdn = new aws.CloudFront()
  @cdn.distributions ?= {}

module.exports.init = (done) ->
  self = this
  buckets = @config.get('aws:s3:buckets')
  cors = @config.get('aws:s3:cors')
  distributions = @config.get('aws:cloudfront:distributions')

  async.series [

    (seriesCallback) ->
      async.each Object.keys(buckets), (key, eachCallback) ->
        bucket = buckets[key]

        self.storage.listBuckets (err, data) ->
          eachCallback(err) if err
          
          for existing in data.Buckets
            if existing.Name is bucket.Bucket
              self.storage.buckets[key] = existing.Name
              eachCallback()
              return

          self.storage.createBucket bucket, (err, data) ->
            self.storage.buckets[key] = data.Bucket if not err
            eachCallback(err)

      , (err, result) ->
        seriesCallback(err)


    (seriesCallback) ->
      async.each Object.keys(cors), (key, eachCallback) ->
        cor = cors[key]

        self.storage.putBucketCors cor, (err, data) ->
          eachCallback(err)

      , (err, result) ->
        seriesCallback(err)


    (seriesCallback) ->
      async.each Object.keys(distributions), (key, eachCallback) ->
        distribution = distributions[key]

        self.cdn.listDistributions {}, (err, data) ->
          for existing in data.Items
            if existing.Comment is distribution.DistributionConfig.Comment
              self.cdn.distributions[key] = existing.Id
              eachCallback()
              return

          distribution.DistributionConfig.CallerReference = new Date().getTime().toString()
          self.cdn.createDistribution distribution, (err, data) ->
            self.cdn.distributions[key] = data.Id if not err
            eachCallback(err)

      , (err, result) ->
        seriesCallback(err)

  ], (err, result) ->
    done(err)
