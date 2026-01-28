export const handler = async (event, context) => {
  const region =
    process.env.AWS_REGION ||
    (context?.invokedFunctionArn ? context.invokedFunctionArn.split(":")[3] : "unknown");

  const isAlb = event?.requestContext?.elb !== undefined;
  const isApiGw = !!event?.requestContext?.apiId || !!event?.requestContext?.stage;

  const headers = event?.headers || {};
  const path = event?.rawPath || event?.path || "/";
  const method = event?.requestContext?.http?.method || event?.httpMethod || "GET";

  const clientIp =
    headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
    event?.requestContext?.http?.sourceIp ||
    event?.requestContext?.identity?.sourceIp ||
    "unknown";

  const payload = {
    message: "Hello from AWS Lambda via Global Accelerator demo",
    region,
    time: new Date().toISOString(),
    method,
    path,
    clientIp,
    via: isAlb ? "ALB → Lambda" : isApiGw ? "API Gateway → Lambda" : "Direct/Function URL → Lambda",
    headers: {
      host: headers.host,
      "x-forwarded-for": headers["x-forwarded-for"],
      "x-forwarded-proto": headers["x-forwarded-proto"],
      "x-forwarded-port": headers["x-forwarded-port"],
      "x-amzn-trace-id": headers["x-amzn-trace-id"],
    },
  };

  if (isAlb) {
    return {
      statusCode: 200,
      statusDescription: "200 OK",
      isBase64Encoded: false,
      headers: {
        "content-type": "application/json",
        "cache-control": "no-store",
        "access-control-allow-origin": "*",
      },
      body: JSON.stringify(payload),
    };
  }

  return {
    statusCode: 200,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
      "access-control-allow-origin": "*",
    },
    body: JSON.stringify(payload),
  };
};
