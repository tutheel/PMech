// email-lambda.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
  const bucketName = process.env.BUCKET_NAME || 'email-bucket';

  const params = {
    Bucket: bucketName,
    Key: `message-${Date.now()}.txt`,
    Body: 'Your message has been emailed'
  };

  try {
    await s3.putObject(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Message saved in email S3 bucket' })
    };
  } catch (error) {
    console.error('Error in Email Lambda:', error);
    throw error;
  }
};
