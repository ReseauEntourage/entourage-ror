'use strict'

const AWS = require('aws-sdk')
const s3 = new AWS.S3()
const sharp  = require('sharp')
// directories
const targetBucket=process.env.target_bucket
const targetDir=process.env.target_dir
const targetSmallDir=process.env.target_small_dir
const sourceDir=process.env.source_dir
// expected sizes
const targetWidth = process.env.target_width
const targetHeight = process.env.target_height
const targetSmallWidth = process.env.target_small_width
const targetSmallHeight = process.env.target_small_height
// expected name
const requestString = process.env.request_string

module.exports.resizeImage = async (event, context) => {
  console.log ('******** START *********' + targetBucket + ' '+ targetSize + ' '+ targetDir + ' ') ;
  //console.log("Event: "+ JSON.stringify(event, null, 2));
  const requestUser = event.Records[0].userIdentity.principalId;
  console.log("Source: "+ requestUser);
  if(requestUser.indexOf(requestString)!=-1) {
    console.log("Internal event: exiting.")
    return
  }

  const srcBucket = event.Records[0].s3.bucket.name
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " ")) ;

  try {
    const typeMatch = srcKey.match(/\.([^.]*)$/) ;
    //TODO check if typematch a au moins 2 parts
    console.info("srcKey="+srcKey);
    //console.info("typeMatch="+typeMatch);
    const imageType = typeMatch[1] ;

    const response = await s3
      .getObject({ Bucket: srcBucket, Key: srcKey })
      .promise() // `.promise()` is unconventional and specific to aws-sdk
    console.log('Getting file from '+srcKey +' on '+srcBucket)

    const keyFolders = srcKey.split("/")

    await s3.copyObject({
        Bucket: targetBucket,
        Key: sourceDir + keyFolders[keyFolders.length - 1],
        CopySource: srcBucket + "/" + srcKey
      })
      .promise()
    console.log("Saving to " + sourceDir + keyFolders[keyFolders.length - 1] + " on " + targetBucket)

    /*
     * Transformations begin
     */
    function transform(data, width, height)
    {
      var image = sharp(data);
      return image
        .metadata()
        .then( function(size) {
          const neww = Math.min(size.width, width);
          const newh = Math.min(size.height, height);
          console.info('Resizing from ' + size.width + 'x' + size.height + " to "+ neww + 'x' + newh) ;
          return image.resize(neww, newh)
            .toBuffer() ;
        })
    }

    const resizedBuffer2 = await transform(response.Body, targetSmallWidth, targetSmallHeight)
    /*if(resizedBuffer)
      console.info('Saving this buffer...'+resizedBuffer) */
    const res2 = await s3
      .putObject({
          Bucket: targetBucket,
          Key: targetSmallDir + keyFolders[keyFolders.length - 1],
          Body: resizedBuffer2
        })
      .promise()
    console.log("Res: "+JSON.stringify(res2, null, 2))
    console.log("Saving to " + targetSmallDir + keyFolders[keyFolders.length - 1] + " on " + targetBucket)

    const resizedBuffer = await transform(response.Body, targetWidth, targetHeight)
    /*if(resizedBuffer)
      console.info('Saving this buffer...'+resizedBuffer) */
    const res = await s3
      .putObject({
          Bucket: targetBucket,
          Key: targetDir + keyFolders[keyFolders.length - 1],
          Body: resizedBuffer
        })
      .promise()
    console.log("Res: "+JSON.stringify(res, null, 2))
    console.log("Saving to " + targetDir + keyFolders[keyFolders.length - 1] + " on " + targetBucket)

    /*
     * Transformations end
     */

  } catch (error) {
    console.error(error)
  }
  console.log ('********** END ************')
}
