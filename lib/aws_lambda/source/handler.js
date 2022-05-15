'use strict'

const AWS = require('aws-sdk')
const s3 = new AWS.S3()
const sharp  = require('sharp')
const targetBucket=process.env.target_bucket
const targetSize = process.env.target_size
const targetDir=process.env.target_dir
const targetSmallSize = process.env.small_target_size
const targetSmallDir=process.env.small_target_dir
const sourceDir=process.env.source_dir
const requestString = process.env.request_string

module.exports.resizeAvatar = async (event, context) => {
  //console.log ('******** START *********' + targetBucket + ' '+ targetSize + ' '+ targetDir + ' ') ;
  //console.log("Event: "+ JSON.stringify(event, null, 2));
  const requestUser = event.Records[0].userIdentity.principalId;
  //console.debug("Source: "+ requestUser);
  if(requestUser.indexOf(requestString)!=-1) {
    console.log("Internal event: exiting.")
    return
  }
  
  const srcBucket = event.Records[0].s3.bucket.name
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " ")) ;

  try {
    const typeMatch = srcKey.match(/\.([^.]*)$/) ;
    //TODO check if typematch a au moins 2 parts
    //console.debug("srcKey="+srcKey);
    //console.info("typeMatch="+typeMatch);
    const imageType = typeMatch[1] ;
  
    const response = await s3
      .getObject({ Bucket: srcBucket, Key: srcKey })
      .promise() // `.promise()` is unconventional and specific to aws-sdk
    console.debug('Getting file from '+srcKey +' on '+srcBucket)

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
    function transform(data, new_size)
    {
      var image = sharp(data);
      return image
        .metadata()
        .then( function(size) {
          const neww = Math.min(size.width,new_size);
          const newh = Math.min(size.height,new_size);
          //console.debug('Resizing from ' + size.width + 'x' + size.height + " to "+ neww + 'x' + newh) ;
          return image.resize(neww, newh)
            .toBuffer() ;
        })
    }
  
    const resizedBuffer2 = await transform(response.Body, targetSmallSize)
    /*if(resizedBuffer)
      console.info('Saving this buffer...'+resizedBuffer) */
    const res2 = await s3
      .putObject({
          Bucket: targetBucket,
          Key: targetSmallDir + keyFolders[keyFolders.length - 1],
          Body: resizedBuffer2
        })
      .promise()
    //console.log("Res: "+JSON.stringify(res2, null, 2))
    console.log("Saving to " + targetSmallDir + keyFolders[keyFolders.length - 1] + " on " + targetBucket)
    
    const resizedBuffer = await transform(response.Body, targetSize)
    /*if(resizedBuffer)
      console.info('Saving this buffer...'+resizedBuffer) */
    const res = await s3
      .putObject({
          Bucket: targetBucket,
          Key: targetDir + keyFolders[keyFolders.length - 1],
          Body: resizedBuffer
        })
      .promise()
    //console.log("Res: "+JSON.stringify(res, null, 2))
    console.log("Saving to " + targetDir + keyFolders[keyFolders.length - 1] + " on " + targetBucket)
    
    /*
     * Transformations end
     */

  } catch (error) {
    console.error(error)
  }
  console.debug ('********** END ************')
}