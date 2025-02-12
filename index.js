// index.js (Lambda function to print Hello World)
exports.handler = async (event) => {
    return {
        statusCode: 200,
        body: JSON.stringify('Hello World'),
    };
  };