package com.searvo.searvo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

class HomeWidgetProvider4x2 : BaseHomeWidgetProvider() {
     override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_4x2).apply {
                
                // Search Bar
                val searchIntent = HomeWidgetProvider.launchApp(context, 
                        uri = Uri.parse("searvo://home?action=search"))
                setOnClickPendingIntent(R.id.widget_search_bar, searchIntent)
                
                // Voice Button
                val voiceIntent = HomeWidgetProvider.launchApp(context, 
                        uri = Uri.parse("searvo://home?action=voice"))
                setOnClickPendingIntent(R.id.widget_voice_btn, voiceIntent)
                
                // Camera Button
                val cameraIntent = HomeWidgetProvider.launchApp(context, 
                        uri = Uri.parse("searvo://home?action=camera"))
                setOnClickPendingIntent(R.id.widget_camera_btn, cameraIntent)
                
                // Discover Button
                val discoverIntent = HomeWidgetProvider.launchApp(context, 
                        uri = Uri.parse("searvo://home?action=discover"))
                setOnClickPendingIntent(R.id.widget_discover_btn, discoverIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
