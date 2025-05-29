exports.handler = async (event) => {
    console.log('Lambda se ejecutó correctamente');
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    const user = event.requestContext.authorizer?.jwt?.claims;
    console.log('User claims:', user);
  
    if (user && user.email) {
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: `Hello from Lambda!`,
            }),
        };
    } else {
        return {
            statusCode: 401,
            body: JSON.stringify({
                message: "Unauthorized: No valid user found",
            }),
        };
    }
  };