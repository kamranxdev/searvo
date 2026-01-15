package com.searvo.searvo

import android.app.PendingIntent
import android.app.TaskStackBuilder
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

class HomeWidgetProvider : BaseHomeWidgetProvider() {
     override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Click
                val pendingIntent = HomeWidgetProvider.launchApp(context, 
                        uri = Uri.parse("searvo://home?action=search"))
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        fun launchApp(context: Context, uri: Uri? = null): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
            if (uri != null) {
                intent.data = uri
            }
            intent.action = Intent.ACTION_VIEW
            
            return TaskStackBuilder.create(context).run {
                addNextIntentWithParentStack(intent)
                getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            }
        }
    }
}
