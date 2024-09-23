// error-handler.js
exports.handler = async (event) => {
    console.error('Error occurred:', event);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'An error occurred', error: event })
    };
  };
  