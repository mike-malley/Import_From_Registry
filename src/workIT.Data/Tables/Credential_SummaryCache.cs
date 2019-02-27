//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace workIT.Data.Tables
{
    using System;
    using System.Collections.Generic;
    
    public partial class Credential_SummaryCache
    {
        public int PK { get; set; }
        public int CredentialId { get; set; }
        public Nullable<int> EntityId { get; set; }
        public System.Guid EntityUid { get; set; }
        public Nullable<System.DateTime> LastSyncDate { get; set; }
        public string CredentialType { get; set; }
        public string CredentialTypeSchema { get; set; }
        public Nullable<int> CredentialTypeId { get; set; }
        public Nullable<System.Guid> OwningAgentUid { get; set; }
        public Nullable<int> OwningOrganizationId { get; set; }
        public Nullable<int> IsAQACredential { get; set; }
        public Nullable<int> HasQualityAssurance { get; set; }
        public string OwningOrgs { get; set; }
        public string OfferingOrgs { get; set; }
        public Nullable<int> LearningOppsCompetenciesCount { get; set; }
        public Nullable<int> AssessmentsCompetenciesCount { get; set; }
        public Nullable<int> RequiresCompetenciesCount { get; set; }
        public Nullable<int> QARolesCount { get; set; }
        public Nullable<int> HasPartCount { get; set; }
        public string HasPartList { get; set; }
        public Nullable<int> IsPartOfCount { get; set; }
        public string IsPartOfList { get; set; }
        public Nullable<int> RequiresCount { get; set; }
        public Nullable<int> RecommendsCount { get; set; }
        public Nullable<int> RequiredForCount { get; set; }
        public Nullable<int> IsRecommendedForCount { get; set; }
        public Nullable<int> IsAdvancedStandingForCount { get; set; }
        public Nullable<int> AdvancedStandingFromCount { get; set; }
        public Nullable<int> PreparationForCount { get; set; }
        public Nullable<int> PreparationFromCount { get; set; }
        public Nullable<int> EntryConditionCount { get; set; }
        public Nullable<int> CorequisiteConditionCount { get; set; }
        public string QARolesList { get; set; }
        public string QAOrgRolesList { get; set; }
        public string QAAgentAndRoles { get; set; }
        public string AgentAndRoles { get; set; }
        public Nullable<int> BadgeClaimsCount { get; set; }
        public Nullable<int> EntityStateId { get; set; }
        public Nullable<int> AvailableAddresses { get; set; }
        public string NaicsList { get; set; }
        public string OtherIndustriesList { get; set; }
        public string LevelsList { get; set; }
        public string OccupationsList { get; set; }
        public string SubjectsList { get; set; }
        public string ConnectionsList { get; set; }
        public string CredentialsList { get; set; }
        public Nullable<decimal> TotalCost { get; set; }
        public Nullable<int> NumberOfCostProfileItems { get; set; }
        public Nullable<int> AverageMinutes { get; set; }
    
        public virtual Credential Credential { get; set; }
    }
}