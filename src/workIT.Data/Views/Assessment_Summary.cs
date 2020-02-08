//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace workIT.Data.Views
{
    using System;
    using System.Collections.Generic;
    
    public partial class Assessment_Summary
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<System.DateTime> DateEffective { get; set; }
        public string IdentificationCode { get; set; }
        public int OrgId { get; set; }
        public string Organization { get; set; }
        public string availableOnlineAt { get; set; }
        public string CTID { get; set; }
        public string CredentialRegistryId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public System.Guid RowId { get; set; }
        public string SubjectWebpage { get; set; }
        public string cerEnvelopeUrl { get; set; }
        public Nullable<int> EntityStateId { get; set; }
        public string AvailabilityListing { get; set; }
        public string AssessmentExampleUrl { get; set; }
        public string ProcessStandards { get; set; }
        public string ScoringMethodExample { get; set; }
        public string ExternalResearch { get; set; }
        public int RequiresCount { get; set; }
        public int RecommendsCount { get; set; }
        public int isRequiredForCount { get; set; }
        public int IsRecommendedForCount { get; set; }
        public int IsAdvancedStandingForCount { get; set; }
        public int AdvancedStandingFromCount { get; set; }
        public int isPreparationForCount { get; set; }
        public int PreparationFromCount { get; set; }
        public string ConnectionsList { get; set; }
        public string CredentialsList { get; set; }
        public string Org_QAAgentAndRoles { get; set; }
        public Nullable<System.Guid> OwningAgentUid { get; set; }
        public string OwningOrganizationCtid { get; set; }
    }
}
