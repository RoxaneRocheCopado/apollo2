import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import callOpenAiApi from '@salesforce/apex/OpenAiApiService.sendRequest';
import closeLabel from '@salesforce/label/c.CLOSE_LABEL';
import copy from '@salesforce/label/c.COPY_TO_CLIPBOARD';
import definitionAs from '@salesforce/label/c.DEFINITION_AS';
import definitionWant from '@salesforce/label/c.DEFINITION_WANT';
import definitionReason from '@salesforce/label/c.DEFINITION_REASON';
import fieldEmpty from '@salesforce/label/c.FIELD_EMPTY';
import labelEmptyFields from '@salesforce/label/c.LABEL_EMPTY_FIELDS';
import labelError from '@salesforce/label/c.ERROR';
import labelSuccess from '@salesforce/label/c.SUCCESS';
import labelWarning from '@salesforce/label/c.WARNING';
import loading from '@salesforce/label/c.LOADING';
import previewModalLabel from '@salesforce/label/c.PREVIEW_MODAL';
import previewRequest from '@salesforce/label/c.PREVIEW_REQUEST';
import promptLabel from '@salesforce/label/c.PROMPT_LABEL';
import rateLimit from '@salesforce/label/c.RATE_LIMIT';
import recommendationLabel from '@salesforce/label/c.RECOMMENDATION_LABEL';
import selectFields from '@salesforce/label/c.SELECT_FIELDS';
import submitRequest from '@salesforce/label/c.SUBMIT_REQUEST';
import suggestionCopied from '@salesforce/label/c.SUGGESTION_COPIED';
import userStoryPrompt from '@salesforce/label/c.USER_STORY_PROMPT';

export default class PreviewModal extends LightningModal {
    @api payload;
    previewText;
    selectedFields = [];
    isLoading = false;
    result;
    labels = {
        closeLabel,
        copy,
        loading,
        previewModalLabel,
        previewRequest,
        promptLabel,
        recommendationLabel,
        selectFields,
        submitRequest,
    };

    get options() {
        return [
            {
                label: 'Title',
                value: 'copado__User_Story_Title__c',
            },
            {
                label: 'Acceptance Criteria',
                value: 'copado__Acceptance_Criteria__c',
            },
            {
                label: 'Technical Specifications',
                value: 'copado__Technical_Specifications__c',
            },
            {
                label: 'Functional Specifications',
                value: 'copado__Functional_Specifications__c',
            },
            {
                label: 'User Story Definition',
                value: 'USER_STORY_DEFINITION',
            }
        ];
    }

    get hasResult() {
        return this.result && this.result !== '';
    }

    get disabled() {
        return this.selectedFields.length === 0;
    }

    handleClose() {
        this.close('okay');
    }

    handleCopy() {
        if (navigator.clipboard && window.isSecureContext) {
            this.showNotification(labelSuccess, suggestionCopied, 'success');
            return navigator.clipboard.writeText(this.result);
        }

        let textArea = document.createElement('textarea');
        textArea.value = this.result;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        return new Promise((res, rej) => {
            document.execCommand('copy') ? res() : rej();
            textArea.remove();
            this.showNotification(labelSuccess, suggestionCopied, 'success');
        });
    }

    handlePreviewChange(event) {
        this.previewText = event.detail.value;
    }

    handleResultChange(event) {
        this.result = event.detail.value;
    }

    handlePreview(event) {
        this.selectedFields = event.detail.value;
        try {
            let previewText = userStoryPrompt + '\n\n';
            const { userStory } = this.payload;
            const emptyFields = [];

            this.selectedFields.forEach((f) => {
                const field = this.options.find((x) => f === x.value);

                if (f === 'USER_STORY_DEFINITION') {
                const as = userStory.fields.copado__userStory_Role__c;
                const want = userStory.fields.copado__userStory_need__c;
                const reason = userStory.fields.copado__userStory_reason__c;

                let definition = '';
                if (as.value && as.value !== '') {
                    definition += `${definitionAs} ${as.value} `;
                }

                if (want.value && want.value !== '') {
                    definition += `${definitionWant} ${want.value} `;
                }

                if (reason.value && reason.value !== '') {
                    definition += `${definitionReason} ${reason.value}`;
                }

                if (definition !== '') {
                    previewText += field.label + ':\n' + definition + '\n\n';
                } else {
                        emptyFields.push(f);
                }
                } else if (userStory.fields[f].value && userStory.fields[f].value !== '') {
                    previewText += field.label + ':\n' + userStory.fields[f].value + '\n\n';
            } else {
                    emptyFields.push(f);
                }
            });

            // TODO: show warning as to some fields are empty
            if (emptyFields.length > 0) {
                this.showNotification(
                    labelWarning,
                    labelEmptyFields + ' ' + emptyFields.map((e) => this.options.find((x) => x.value ===e).label).join(', '),
                    'warning',
                );
            }

            this.previewText = previewText
                .replace(/<\/?[^>]+(>|$)/g, "")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", '"')
                .replace("&apos;", "'");
        } catch (err) {
            console.error(err);
        }
    }

    async handleSubmit() {
        try {
            this.isLoading = true;

            if (this.selectedFields.length === 0) {
                this.showNotification(labelError, fieldEmpty, 'error');

                return;
            }

            if (!this.previewText || this.previewText === '') {
                this.handlePreview();

                if (!this.previewText || this.previewText === '') {
                    this.showNotification(labelWarning, fieldEmpty, 'error');

                    return;
                }
            }

            const { max_tokens, temperature, engine } = this.payload;

            const body = JSON.stringify({
                'model': engine || 'gpt-3.5-turbo',
                'messages': [{
                    'role':'user',
                    'content': this.previewText,
                }],
                'max_tokens': Number(max_tokens || 200),
                'temperature': Number(temperature || 1),
                'top_p': 1,
                'stream': false
            });

            const data = await callOpenAiApi({ body });

            if (data.isSuccess === true) {
                let response = JSON.parse(data.response);

                this.result = response.choices[0].message.content.trim();
            } else {
                if (data.status === 429) {
                    this.showNotification(labelError, rateLimit, 'error');
                } else {
                    this.showNotification(data.status, data.message, 'error');
                }
            }
        } catch(err) {
            console.error(err);

            if (err.status === 429) {
                this.showNotification(rateLimit, err.statusText, 'error');
            } else if (err.status === 500 || err.status === 501) {
                this.showNotification(labelError, err.statusText, 'error');
            } else {
                this.showNotification(labelError, err.message, 'error');
            }
        } finally {
            this.isLoading = false;
        }
    }

    showNotification(title, message, variant) {
        const dispatcher = this.template.querySelector('c-copado-ai-helper-dispatcher');

        if (dispatcher) {
            dispatcher.dispatch(title, message, variant);
        }
    }
}