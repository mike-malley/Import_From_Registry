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
    
    public partial class Entity_AgentRelationship
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public int RelationshipTypeId { get; set; }
        public System.Guid AgentUid { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public System.Guid RowId { get; set; }
        public Nullable<bool> IsInverseRole { get; set; }
    
        public virtual Codes_AssertionType Codes_AssertionType { get; set; }
        public virtual Entity Entity { get; set; }
    }
}