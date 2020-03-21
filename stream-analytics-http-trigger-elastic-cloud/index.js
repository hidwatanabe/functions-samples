const { Client } = require('@elastic/elasticsearch')
const client = new Client({
    cloud: {
        id: "<enter_your_cloud_id>"
    },
    auth: {
        username: '<username>',
        password: '<password>'
    }
})

module.exports = async function (context, req) {
    req.body.forEach((message) => {
        context.log(`data ${JSON.stringify(message)}`);
        client.index({
            index: 'iot-asa-func-nodejs-es',
            body: `${JSON.stringify(message)}`
        })
    });
};
