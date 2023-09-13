import { api, wire } from 'lwc';
import { LightningElement } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import callOpenAiApi from '@salesforce/apex/OpenAiApiService.sendRequest';
import processQuestion from '@salesforce/apex/OpenAIQuestionProcessor.processQuestion';
import getAvailableQuestionsFor from '@salesforce/apex/OpenAIQuestionProcessor.getAvailableQuestionsFor';
import actionResponseCall from '@salesforce/apex/Action.callAction';


import UserId from '@salesforce/user/Id';
import UserName from '@salesforce/schema/User.Name';
import UserLanguageLocaleKey from '@salesforce/schema/User.LanguageLocaleKey';


import LOADING from '@salesforce/label/c.LOADING';
import CHAT_SELECT_PROMPT_LABEL from '@salesforce/label/c.CHAT_SELECT_PROMPT_LABEL';
import CHAT_SELECT_PROMPT_PLACEHOLDER from '@salesforce/label/c.CHAT_SELECT_PROMPT_PLACEHOLDER';
import CHAT_ASK_OPENAI_LABEL from '@salesforce/label/c.CHAT_ASK_OPENAI_LABEL';
import CHAT_SEND_BUTTON_LABEL from '@salesforce/label/c.CHAT_SEND_BUTTON_LABEL';
import CHAT_CLEAR_CONVERSATION_BUTTON_LABEL from '@salesforce/label/c.CHAT_CLEAR_CONVERSATION_BUTTON_LABEL';
import CHAT_OPENAI_PRIVACY_POLICY_LINK from '@salesforce/label/c.CHAT_OPENAI_PRIVACY_POLICY_LINK';
import CHAT_ASK_OPENAI_PLACEHOLDER from '@salesforce/label/c.CHAT_ASK_OPENAI_PLACEHOLDER';


const CONTINUE = 'Please continue';

export default class Copado_devops_ai_companion extends LightningElement {
    @api contextId;
    @api max_tokens;
    @api temperature;
    @api engine;
    
    username;
    userLanguageCode;
    userMessage;
    selectedQuestion;
    isLoading = false;
    more = false;
    pageReferenceCalled=false;
    selectedQuestionRec;

    availableQuestions = [];
    availableQuestionMapByLabel = {};
    hasAvailableQuestions = false;
    messages = [];

    // everything for the actions
    fuctionsClassMap = {};
    functions = [];
    functionExamples = [];

    // dynamically calculated label
    CHAT_ASK_OPENAI_LABEL_DYNAMIC =  CHAT_ASK_OPENAI_LABEL;
    
    labels = {
        LOADING,
        CHAT_SELECT_PROMPT_LABEL,
        CHAT_SELECT_PROMPT_PLACEHOLDER,
        CHAT_ASK_OPENAI_LABEL,
        CHAT_ASK_OPENAI_PLACEHOLDER,
        CHAT_SEND_BUTTON_LABEL,
        CHAT_CLEAR_CONVERSATION_BUTTON_LABEL,
        CHAT_OPENAI_PRIVACY_POLICY_LINK,
    }

    @wire(getRecord, { recordId: UserId, fields: [UserName, UserLanguageLocaleKey] })
    currentUserInfo({ error, data }) {
        if(data) {
            this.username = data.fields.Name.value;
            // NOTE: if it is not english/us we concatenate the language code of this user
            // so they can troubleshoot why and who sees which Prompts
            const lang = data.fields.LanguageLocaleKey.value?.replace(/_.*/, '');
            if(lang != 'en') {
                this.username += ` (${lang})`;
            }
        }else if (error) {
            this.error = error;
        }
    }

    @wire(CurrentPageReference) handlePageReference(pageReference) {
        this.contextId = pageReference.attributes?.recordId || this.extractRecordIdFromUrl();
        this.pageReferenceCalled = true;
        // only re-initialize if there is no conversation going on
        if(this.messages.length==0) {
            this.handleClear();
        }
    }

    connectedCallback() {
        this.template.addEventListener('openaicontinue', this.handleSubmit.bind(this));
    }

    renderedCallback() {
        this.scrollToBottom();
        if(!this.pageReferenceCalled) {
            this.pageReferenceCalled = true;
            this.contextId = this.extractRecordIdFromUrl();
            this.initializePromptsAndObject();
        }
    }

    initializePromptsAndObject() {
        getAvailableQuestionsFor({ contextId: this.contextId })
        .then((result) => {
            console.debug('initializePromptsAndObject', this.contextId, result);
            this.CHAT_ASK_OPENAI_LABEL_DYNAMIC = this.labels.CHAT_ASK_OPENAI_LABEL + ' ' + result.objectLabel;
            this.availableQuestions = result.prompts.map(x => ({label: x.label, value: x.label}));
            this.availableQuestionMapByLabel = Object.fromEntries(result.prompts.map(x => [x.label, x]));
            this.hasAvailableQuestions = this.availableQuestions.length > 0;

            this.fuctionsClassMap = {};
            this.functions = [];
            this.functionExamples = [];
            if(result.actions && Object.keys(result.actions).length) {
                for(let [className, schema] of Object.entries(result.actions)) {
                    schema = JSON.parse(schema);
                    this.functionExamples = this.functionExamples.concat( schema.examples.map(x => ({label: x, value: x})) );
                    delete schema.examples; // need to remove it... it is not part of OpenaI
                    this.functions.push(schema);
                    this.fuctionsClassMap[schema.name] = className;
                }
            }
        })
        .catch((err) => {
            this.showErrorMessage(err, 'There was an error');
            this.hasAvailableQuestions = this.availableQuestions.length > 0;
        });
    }

    scrollToBottom() {
        const scrollArea = this.template.querySelector('lightning-textarea');
        scrollArea.scrollTop = scrollArea.scrollHeight;
        scrollArea.scrollIntoView();
    }

    get hasMessages() {
        return this.messages.length > 0;
    }

    handleUserMesssage(event){
        this.userMessage = event.target.value;
    }

    handleClear() {
        this.selectedQuestion = undefined;
        this.selectedQuestionRec = undefined;
        this.userMessage = '';
        this.messages = [];
        const textArea = this.template.querySelector("lightning-textarea");
        if(textArea) {
            textArea.value = "";
            textArea.placeholder = this.labels.CHAT_ASK_OPENAI_PLACEHOLDER;
        }
        // re-read the context id, in case the user navigated to another record
        this.initializePromptsAndObject();
        this.template.host.style.setProperty('--textareHeight', '');
    }

    async handleSelectQuestion(event) {
        this.selectedQuestion = event.detail.value;
        this.selectedQuestionRec = this.availableQuestionMapByLabel[this.selectedQuestion];

        processQuestion({
            contextId: this.contextId,
            questionRec: this.selectedQuestionRec
        }).then((result) => {
            this.selectedQuestionRec = result;
            this.userMessage = result.prompt;
            const textArea = this.template.querySelector('lightning-textarea');
            textArea.value = this.userMessage;
            textArea.focus();
            // NOTE: lwc at this time does not support textArea.setSelectionRange()
            // so no subtext selection is possible
        }).catch((err) => {
            this.showErrorMessage(err, 'There was an error(1)');
            this.isLoading=false;
        });
    }

    async handleSubmit(event) {

        if(event.type === 'openaicontinue') {
            event.stopPropagation();
        }

        if(!this.userMessage && event.type !== 'openaicontinue') {
            return
        }

        try {
            this.template.host.style.setProperty('--textareHeight', '0.5rem');
            this.isLoading = true;
            this.scrollToBottom();

            let chatGPTmessages = [{
                "role": "system",
                "content": "You need to assist the person asking you questions and tasks about Copado. Copado is a Salesforce Devops and Deployment tool, and most of changes in User Stories, Promotions and Deployments are related to Salesforce features and Salesforce metadata"
            }];
            // override the default assistant message
            if(this.selectedQuestionRec?.before) {
                chatGPTmessages[0].content = this.selectedQuestionRec.before;
            }

            // add the last user message to the queue, and clear the input
            if(event.type !== 'openaicontinue') {
                this.addMessage(this.userMessage, true);
                this.userMessage = '';
            }

            chatGPTmessages = chatGPTmessages.concat(this.messages.map((m) => ({
                content: m.content,
                role: m.role,
            })));

            // if we clicked on continue, send a "please continue" message, but do not add it to the conversation
            if(event.type === 'openaicontinue') {
                chatGPTmessages.push({
                    content: CONTINUE,
                    role: 'user',
                });
            }

            let body = {
                'messages': chatGPTmessages,
                'top_p': 1,
                'stream': false
            };

            if(this.functions.length) {
                body.functions = this.functions;
            }
            body = JSON.stringify(body);
            const data = await callOpenAiApi({ body });
            if(!data.isSuccess) {
                throw new Error(data.message || data);
            }

            let response = JSON.parse(data.response);
            let more = response.choices[0].finish_reason === 'length';
            response.choices[0].message.content = response.choices[0].message.content || '';
            console.debug('response', response);
            if(response.choices[0].message.function_call) {
                if(more) {
                    response.choices[0].message.content = response.choices[0].message.content || '(there was an error trying to execute the OpenAI Function: not enough tokens. Try increasing the Max Tokens fields in the Copado AI Companion configuration)'
                    more = false;
                }else{
                    const fn = response.choices[0].message.function_call;
                    const args = JSON.parse(fn.arguments);
                    let className = this.fuctionsClassMap[fn.name];
                    let actionResult = await actionResponseCall({contextId: this.contextId, name: className, args: args});
                    // TODO: error handling? both general and specific error messages in actionResult.error
                    response.choices[0].message.content += actionResult.message||'';
                    response.choices[0].message.content += actionResult.error||'';
                }
            }

            if(event.type === 'openaicontinue') {
                // append to that message.
                this.messages[this.messages.length - 1].content += ' ' + response.choices[0].message.content.trim();
                this.messages[this.messages.length - 1].more = more;
            } else {
                this.addMessage(response.choices[0].message.content.trim(), false, more);
            }

            const textArea = this.template.querySelector('lightning-textarea');

            textArea.placeholder = 'ask follow-up questions or additional instructions...';

        } catch(err) {
            this.showErrorMessage(err, 'There was an error(2)');
        } finally {
            this.isLoading = false;
            this.scrollToBottom();
        }
    }

    handleAction(event) {
        // simulate typing
        this.userMessage = event.target.value;
        event.target.value = '';
        this.handleSubmit(new CustomEvent('click'));
    }

    addMessage(content, fromUser, more) {
        this.messages.push({
            timestamp: this.messages.length,
            content: '' + content,
            role: fromUser ? 'user' : 'system',
            more,
        });
    }

    showErrorMessage(err, prefix) {
        console.error(err);
        let userError = err.body
            ? (err.body.message ? `${err?.body?.message}\n${err.body.exceptionType||''}\n${err.body.stackTrace||''}` : err.body)
            : err;
        this.addMessage(`* ${prefix||''}: ${userError}`, false);
        const event = new ShowToastEvent({
            title: 'There was an error',
            message: userError,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    extractRecordIdFromUrl() {
        // complex way to parse several url types and extract a relevant ID
        // only used in Deployment and similar Pages
        let recordId = null;
        let t = window.location.href;
        let m = /\/one\/one.app#(.*)/i.exec(t);
        if(m) {
            try{
                t = m[1];
                t = decodeURIComponent(t);
                t = atob(t);
                t = JSON.parse(t);
                t = t.attributes.address;
            }catch(e) {
                console.error('Error while decoding one.app urls', e, t);
            }
        }
        m = /[a-z0-9_]+__c\/([a-z0-9]{18})/i.exec(t);
        if(m) {
            recordId = m[1];
        }else{
            let m = /[?&](?:record)?id=([a-z0-9]{15,18})/i.exec(t);
            if(m) {
                recordId = m[1];
            }
        }
        console.debug('extractRecordIdFromUrl', t, recordId);
        return recordId;
    }
}