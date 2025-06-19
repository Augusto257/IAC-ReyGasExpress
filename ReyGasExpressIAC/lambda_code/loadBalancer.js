exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const random = Math.random();
    
    const primaryWeight = 0.7;
    const endpoint = random < primaryWeight 
        ? process.env.PRIMARY_ENDPOINT 
        : process.env.SECONDARY_ENDPOINT;
    
    request.origin.custom.domainName = endpoint.replace('https://', '').split('/')[0];
    request.origin.custom.path = `/${endpoint.split('/').slice(3).join('/')}${request.uri}`;
    request.headers['host'] = [{ key: 'host', value: endpoint.replace('https://', '').split('/')[0] }];
    
    return request;
};