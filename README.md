# dtlelearnlab

This is the staging ground for developing an extended eLearning framework for enhancing use of DevTest Labs. The working solution will allow for students to go to a website for a signup form, once submitted they will receive an elearning environment automatically spun up using DevTest Labs. This is abstracted away from the student, they do not use the Azure or DTL portal but receive a redirect link or RDP file via email or download to RDP to their student jumpbox. The student jumpbox in turn had RDMan for their VMs in this sample a CustomImage VM of a Windows Active Directory Domain Controller with a fictional AD Forest domain. One can envision adding additional VMs with 3rd party ISV software to the solution to build and create a more rich lab experience for their Students.

The eLearning platform is levergaing a Angular 2 WebApp build using the Radzen UI builder, Azure Automation PowerSHell WorkFlow Runbbok to orchestrate the submission of the course and creation of the lab for the student in DTL passing parameters and using ARM Templates stored on GitHub Repo.

Advantages: 

1. Easy Webform submission system for student posting a web hook
2. Automation and orchestration of isolated lab environment for student
3. Student of ISV software is not exposed to Azure or has to learn Azure but the solution in Windows or Linux, full abstraction of process to Student
4. Easy to use DTL interface to build custom Images for courses
5. Easy to use DTL ARM Template to deploy Custom Image VMs with ISV software and environment preinstalled
6. DTL has a expiration feature and this solution passes a parameter to VM \ Lab creation to delete VMs after 1 hour, helps reduce cost to host. Do not pay for colocation \ hypervisor, cheap rates to host students.

Still to Work On:

Radzen WebApp Submit button does not POST HTTP to Web hook automation job

Automation Orchestration Engine captures outputs, however need to be stored in Storage Table and use the student PIP to send to the student
