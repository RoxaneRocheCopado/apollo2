import { LightningElement, api } from 'lwc';
import useAI from '@salesforce/label/c.USE_AI';
import privacyPolicy from '@salesforce/label/c.PRIVACY_POLICY';
import headerLabel from '@salesforce/label/c.HEADER_LABEL';


export default class CopadoAiHelper extends LightningElement {
    @api recordId;
    @api max_tokens;
    @api temperature;
    @api engine;
    userStory;

    label = {
        useAI,
        headerLabel,
        privacyPolicy,
    };

    async handlePreview() {
        window.open('/flow/copadoAiHelper/Copado_DevOps_AI_Companion?recordId='+this.recordId, '_blank', 'height=600,location=no,resizable=yes,toolbar=no,status=no,menubar=no,scrollbars=1');
    }
}