// request-handler.js
const AWS = require('aws-sdk');
const eventBridge = new AWS.EventBridge();

exports.handler = async (event) => {
  try {
    const action = event.action;
    if (!action) {
      throw new Error('No action provided');
    }

    // Prepare EventBridge entry
    const params = {
      Entries: [
        {
          Source: 'custom.event',
          DetailType: 'ActionTrigger',
          Detail: JSON.stringify({ action }),
          EventBusName: 'default'
        }
      ]
    };

    // Send the event to EventBridge
    await eventBridge.putEvents(params).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: `Event for action "${action}" triggered successfully.` })
    };
  } catch (error) {
    console.error('Error in Request Handler:', error);
    throw error;
  }
};
