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
    
    public partial class SiteTotalsSummary
    {
        public int Id { get; set; }
        public Nullable<int> TotalOrgs { get; set; }
        public Nullable<int> TotalDirectOrgs { get; set; }
        public Nullable<int> TotalQAOrgs { get; set; }
        public int TotalPartnerCredentials { get; set; }
        public Nullable<int> TotalEnteredCredentials { get; set; }
        public int TotalPendingCredentials { get; set; }
        public Nullable<int> TotalDirectCredentials { get; set; }
        public Nullable<int> TotalOtherCredentials { get; set; }
        public Nullable<int> TotalCredentialsAtCurrentCtdl { get; set; }
        public Nullable<int> TotalCredentialsToBeUpdatedToCurrentCtdl { get; set; }
    }
}