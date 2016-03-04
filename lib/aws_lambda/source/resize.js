var AWS = require('aws-sdk') ;
var gm  = require('gm').subClass({ imageMagick: true }) ;
var s3  = new AWS.S3() ;

exports.handler = function(event, context)
{
  var srcBucket = event.Records[0].s3.bucket.name ;
  var srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " ")) ;

  function get_object_from_s3(cb)
  {
    s3.getObject ({ Bucket: srcBucket, Key: srcKey }, cb) ;
  }

  function put_object_s3(params, cb)
  {
    s3.putObject(params, function(err, data) {
      if (err) context.fail ('put_object_s3 error') ;
      cb() ;
    }) ;
  }

  function transform(data, cb)
  {

    gm (data.Body)
        .resize (400)
        .toBuffer(imageType, function(err, buffer) {
          if (err) context.fail('transform_m error') ;

          var params = {  Bucket: srcBucket+'-thumb',
            Key: srcKey,
            Body: buffer } ;

          put_object_s3 (params, cb) ;
        }) ;
  }


  function done(err)
  {
    console.log ('********** END ************') ;
    context.succeed () ;
  }


  function run()
  {
    console.log ('******** START *********') ;

    get_object_from_s3(function (err, data) {
      if (err) context.fail('Cannot get object from S3');
      transform(data, done);
    });
  }

  run () ;
};