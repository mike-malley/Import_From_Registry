﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using workIT.Models;
using workIT.Models.Common;
using ThisEntity = workIT.Models.Common.Entity_CommonCost;
using DBEntity = workIT.Data.Tables.Entity_CommonCost;
using EntityContext = workIT.Data.Tables.workITEntities;
using ViewContext = workIT.Data.Views.workITViews;

using workIT.Utilities;
using CM = workIT.Models.Common;

using EM = workIT.Data.Tables;
using Views = workIT.Data.Views;
namespace workIT.Factories
{
	public class Entity_CommonCostManager : BaseFactory
	{
		static string thisClassName = "Entity_CommonCostManager";

		#region === Persistance ===================
		public bool SaveList( List<int> list, Guid parentUid, ref SaveStatus status )
		{
            //first do a deleteAll
            Entity parent = EntityManager.GetEntity( parentUid );
            if ( parent == null || parent.Id == 0 )
            {
                status.AddError( "Error - the parent entity was not found." );
                return false;
            }
            DeleteAll( parent, ref status );

            if ( list == null || list.Count == 0 )
				return true;

			bool isAllValid = true;
			foreach ( int item in list )
			{
				Save( parent, item, ref status );
			}

			return isAllValid;
		}
		/// <summary>
		/// Add an Entity_CommonCost
		/// </summary>
		/// <param name="parentUid"></param>
		/// <param name="profileId"></param>
		/// <param name="userId"></param>
		/// <param name="messages"></param>
		/// <returns></returns>
		private int Save( Entity parent,
					int costManifestId,
					ref SaveStatus status )
		{
			int id = 0;
			
			if ( costManifestId == 0 )
			{
				status.AddError( string.Format( "A valid CostManifest identifier was not provided to the {0}.Add method.", thisClassName ) );
				return 0;
			}

			//Entity parent = EntityManager.GetEntity( parentUid );
			if ( parent == null || parent.Id == 0 )
			{
				status.AddError( "Error - the parent entity was not found." );
				return 0;
			}

			//need to check the whole chain
			if ( parent.EntityTypeId == CodesManager.ENTITY_TYPE_COST_MANIFEST
				&& parent.EntityBaseId == costManifestId )
			{
				status.AddError( "Error - you cannot add a Cost manifest as a common Cost to itself." );
				return 0;
			}
			using ( var context = new EntityContext() )
			{
				DBEntity efEntity = new DBEntity();
				try
				{
					//first check for duplicates
					efEntity = context.Entity_CommonCost
							.SingleOrDefault( s => s.EntityId == parent.Id
							&& s.CostManifestId == costManifestId );

					if ( efEntity != null && efEntity.Id > 0 )
					{
						status.AddError( string.Format( "Error - this CostManifest has already been added to this profile.", thisClassName ) );
						return 0;
					}

					efEntity = new DBEntity();
					efEntity.EntityId = parent.Id;
					efEntity.CostManifestId = costManifestId;

					efEntity.Created = System.DateTime.Now;

					context.Entity_CommonCost.Add( efEntity );

					// submit the change to database
					int count = context.SaveChanges();
					if ( count > 0 )
					{
						id = efEntity.Id;
						return efEntity.Id;
					}
					else
					{
						//?no info on error
						status.AddError( "Error - the add was not successful." );
						string message = thisClassName + string.Format( ".Add Failed", "Attempted to add a CostManifest for a profile. The process appeared to not work, but there was no exception, so we have no message, or no clue. Parent Profile: {0}, Type: {1}, costManifestId: {2}", parent.EntityUid, parent.EntityType, costManifestId );
						EmailManager.NotifyAdmin( thisClassName + ".Add Failed", message );
					}
				}
				catch ( Exception ex )
				{
					string message = FormatExceptions( ex );
					status.AddError( "Error - the save was not successful. " + message );
					LoggingHelper.LogError( ex, thisClassName + string.Format( ".Save(), Parent: {0} ({1})", parent.EntityBaseName, parent.EntityBaseId ) );
				}
			}
			return id;
		}
		public bool IsParent( Entity parent, int CostManifestBeingCheckedId, ref string statusMessage )
		{
			bool isOK = true;
			if ( parent.EntityTypeId == CodesManager.ENTITY_TYPE_COST_MANIFEST
				&& parent.EntityBaseId == CostManifestBeingCheckedId )
			{
				statusMessage = "Error - you cannot add this Cost manifest as a common Cost as it is the same as the parent Cost manifest or a grand parent (or somewhere up the hierarchy).";
				return false;
			}
			//check for a parent Cost manifest
			//get all commonCosts, with parent CM
			return isOK;
		}
		//public bool Delete( Guid parentUid, int profileId, ref string statusMessage )
		//{
		//	bool isValid = false;
		//	if ( profileId == 0 )
		//	{
		//		statusMessage = "Error - missing an identifier for the Assessment to remove";
		//		return false;
		//	}
		//	//need to get Entity.Id 
		//	Entity parent = EntityManager.GetEntity( parentUid );
		//	if ( parent == null || parent.Id == 0 )
		//	{
		//		statusMessage = "Error - the parent entity was not found.";
		//		return false;
		//	}

		//	using ( var context = new EntityContext() )
		//	{
		//		DBEntity efEntity = context.Entity_CommonCost
		//						.SingleOrDefault( s => s.EntityId == parent.Id && s.CostManifestId == profileId );

		//		if ( efEntity != null && efEntity.Id > 0 )
		//		{
		//			context.Entity_CommonCost.Remove( efEntity );
		//			int count = context.SaveChanges();
		//			if ( count > 0 )
		//			{
		//				isValid = true;
		//			}
		//		}
		//		else
		//		{
		//			statusMessage = "Warning - the record was not found - probably because the target had been previously deleted";
		//			isValid = true;
		//		}
		//	}

		//	return isValid;
		//}
        public bool DeleteAll( Entity parent, ref SaveStatus status )
        {
            bool isValid = true;
            //Entity parent = EntityManager.GetEntity( parentUid );
            if ( parent == null || parent.Id == 0 )
            {
                status.AddError( thisClassName + ". Error - the provided target parent entity was not provided." );
                return false;
            }
            using ( var context = new EntityContext() )
            {
                context.Entity_CommonCost.RemoveRange( context.Entity_CommonCost.Where( s => s.EntityId == parent.Id ) );
                int count = context.SaveChanges();
                if ( count > 0 )
                {
                    isValid = true;
                }
                else
                {
                    //if doing a delete on spec, may not have been any properties
                }
            }

            return isValid;
        }
        #endregion

        /// <summary>
        /// Get all CostManifests for the provided entity
        /// The returned entities are just the basic, unless for the detail view
        /// </summary>
        /// <param name="parentUid"></param>
        /// <returns></returns>
        public static List<CostManifest> GetAll( Guid parentUid )
		{
			List<CostManifest> list = new List<CostManifest>();
			CostManifest entity = new CostManifest();

			Entity parent = EntityManager.GetEntity( parentUid );
			LoggingHelper.DoTrace( 7, string.Format( "Entity_CommonCostManager_GetAll: parentUid:{0} entityId:{1}, e.EntityTypeId:{2}", parentUid, parent.Id, parent.EntityTypeId ) );

			try
			{
				using ( var context = new EntityContext() )
				{
					List<DBEntity> results = context.Entity_CommonCost
							.Where( s => s.EntityId == parent.Id )
							.OrderBy( s => s.CostManifestId )
							.ToList();

					if ( results != null && results.Count > 0 )
					{
						foreach ( DBEntity item in results )
						{
							entity = new CostManifest();
                            //
                            //Need all the data for detail page - NA 6/2/2017
                            if ( item.CostManifest != null && item.CostManifest.Id > 0 && item.CostManifest.EntityStateId > 2 )
                            {
                                entity = CostManifestManager.Get( item.CostManifestId );
                                list.Add( entity );
                            }
						}
					}
					return list;
				}
			}
			catch ( Exception ex )
			{
				LoggingHelper.LogError( ex, thisClassName + ".GetAll" );
			}
			return list;
		}

		public static List<CostManifest> GetAllManifestInCommonCostsFor( int CostManifestId, int CostManifestBeingCheckedId )
		{
			List<CostManifest> list = new List<CostManifest>();


			try
			{
				using ( var context = new EntityContext() )
				{
					List<DBEntity> results = context.Entity_CommonCost
							.Where( s => s.CostManifestId == CostManifestId )
							.OrderBy( s => s.EntityId )
							.ToList();

					if ( results != null && results.Count > 0 )
					{
						foreach ( DBEntity item in results )
						{
							if ( item.Entity.EntityBaseId == CostManifestBeingCheckedId )
							{

							}
						}
					}
					return list;
				}
			}
			catch ( Exception ex )
			{
				LoggingHelper.LogError( ex, thisClassName + ".GetAllManifestInCommonCostsFor" );
			}
			return list;
		}

	}
}
