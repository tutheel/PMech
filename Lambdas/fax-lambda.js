// fax-lambda.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
  const bucketName = process.env.BUCKET_NAME || 'fax-bucket';

  const params = {
    Bucket: bucketName,
    Key: `message-${Date.now()}.txt`,
    Body: 'Your message has been faxed'
  };

  try {
    await s3.putObject(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Message saved in fax S3 bucket' })
    };
  } catch (error) {
    console.error('Error in Fax Lambda:', error);
    throw error;
  }
};
