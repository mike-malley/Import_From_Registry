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
    
    public partial class CodesProperty_Summary
    {
        public int PK { get; set; }
        public int CategoryId { get; set; }
        public string Category { get; set; }
        public string CategorySchemaName { get; set; }
        public string CategorySchemaUrl { get; set; }
        public Nullable<bool> CategoryIsActive { get; set; }
        public Nullable<int> PropertyId { get; set; }
        public string Property { get; set; }
        public string PropertyDescription { get; set; }
        public Nullable<int> SortOrder { get; set; }
        public string PropertySchemaName { get; set; }
        public string ParentSchemaName { get; set; }
        public string PropertySchemaUrl { get; set; }
        public int Totals { get; set; }
    }
}