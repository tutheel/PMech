// print-lambda.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
  const bucketName = process.env.BUCKET_NAME || 'print-bucket';

  const params = {
    Bucket: bucketName,
    Key: `message-${Date.now()}.txt`,
    Body: 'Your message has been printed'
  };

  try {
    await s3.putObject(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Message saved in print S3 bucket' })
    };
  } catch (error) {
    console.error('Error in Print Lambda:', error);
    throw error;
  }
};
