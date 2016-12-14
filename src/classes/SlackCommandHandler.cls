/**
 * API Endpoint that gets called by slack.  Slack request example:
 * token=gIkuvaNzQIHg97ATvDxqgjtO
 * team_id=T0001
 * team_domain=example
 * channel_id=C2147483705
 * channel_name=test
 * user_id=U2147483697
 * user_name=Steve
 * command=/weather
 * text=94070
 * response_url=https://hooks.slack.com/commands/1234/5678
 */

@RestResource(urlMapping='/slack')
global class SlackCommandsHandler {

    private static final String API_TOKEN = Labels.Slack_API_Token;

    private static final List<Slack_Command__mdt> cmds = [SELECT Command_Key__c, Immediate__c, Class_Name__c
                                                            FROM Slack_Command__mdt WHERE Active__c = true];

    /**
     * Must Respond with something in 3000ms! We kick off a batch to allow for longer processing.
     * @return Repsonse Object
     */
    @HttpPost
    global static SlackCommand.SlackResponse respond() {
        RestRequest req = RestContext.request;
        if(req.params.get('token') == API_TOKEN){
            String commandKey = req.params.get('text').split(' ')[0];

            //return help
            if(commandKey == 'help'){
                return new SlackCommand.SlackResponse(Label.Slack_Command_Help_Message);
            }

            //process immediate commands
            Map<String, Slack_Command__mdt> immediateCommands = getImmediateCommands();
            if(immediateCommands.containsKey(commandKey)){
                SlackCommand.SlackCommandParams params = new SlackCommand.SlackCommandParams(req.params);
                ISlackCommand cmd = initCommand(immediateCommands.get(commandKey));
                SlackCommand.SlackResponse resp = cmd.getResponse(params);
                resp.text = resp.text;
                cmd.runDML();
                return resp;
            }else{
                respondDelayed(commandKey, req.params);
            }

            return new SlackCommand.SlackResponse('Processing Request...');
        }
        return null;
    }

    //gets commands that must return immediately (we check these first to help ensure they respond within time limit)
    private static Map<String, Slack_Command__mdt> getImmediateCommands(){
        Map<String, Slack_Command__mdt> immediateCommands = new Map<String, Slack_Command__mdt>();
        for(Slack_Command__mdt cmd : cmds){
            if(cmd.Immediate__c){
                immediateCommands.put(cmd.Command_Key__c, cmd);
            }
        }
        return immediateCommands;
    }

    // Processes delayed commands. Responds by calling response_url
    @future(callout=true)
    private static void respondDelayed(String commandKey, Map<String, String> paramsMap){
        SlackCommand.SlackCommandParams params = new SlackCommand.SlackCommandParams(paramsMap);
        SlackCommand.SlackResponse resp;
        ISlackCommand cmd;
        try{
            Map<String, Slack_Command__mdt> delayedCommands = getDelayedCommands();
            if(delayedCommands.containsKey(commandKey)){
                cmd = initCommand(delayedCommands.get(commandKey));
                resp = cmd.getResponse(params);
            }
            if(resp == null){
                resp = new SlackCommand.SlackResponse('Invalid Command!  See `/[cmd] help`.');
            }
        }catch(Exception e){
            resp = new SlackCommand.SlackResponse('Failed to Process Request: ' + e.getMessage() +
                '\nStack Trace: ' + e.getStackTraceString());
        }
        sendMessage(resp, params.responseUrl);
        cmd.runDML();
    }

    //these commands can take longer than 3000ms
    private static Map<String, Slack_Command__mdt> getDelayedCommands(){
        Map<String, Slack_Command__mdt> delayedCommands = new Map<String, Slack_Command__mdt>();
        for(Slack_Command__mdt cmd : cmds){
            if(cmd.Immediate__c == false){
                delayedCommands.put(cmd.Command_Key__c, cmd);
            }
        }
        return delayedCommands;
    }

    // respond to slack command URL
    private static void sendMessage(SlackCommand.SlackResponse msg, String responseUrl){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(responseUrl);
        req.setMethod('POST');
        req.setBody(JSON.serialize(msg));
        req.setHeader('content-type', 'application/json');
        Http http = new Http();
        HttpResponse response = http.send(req);
    }

    //dynamicly inits command class
    private static ISlackCommand initCommand(Slack_Command__mdt cmdObj){
        Type t = Type.forName(cmdObj.Class_Name__c);
        return (ISlackCommand) t.newInstance();
    }

}