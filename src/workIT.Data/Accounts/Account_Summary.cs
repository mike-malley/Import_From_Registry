//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace workIT.Data.Accounts
{
    using System;
    using System.Collections.Generic;
    
    public partial class Account_Summary
    {
        public int Id { get; set; }
        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string FullName { get; set; }
        public string SortName { get; set; }
        public string Email { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public System.DateTime Created { get; set; }
        public System.DateTime LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
        public System.Guid RowId { get; set; }
        public string AspNetId { get; set; }
        public string Roles { get; set; }
        public string OrgMbrs { get; set; }
        public Nullable<System.DateTime> lastLogon { get; set; }
        public string CEAccountIdentifier { get; set; }
    }
}
